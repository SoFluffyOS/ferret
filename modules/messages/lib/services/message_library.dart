import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:fixnum/fixnum.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/cache_store.dart';
import 'package:messages/services/message_cache.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/messages.dart';

/// A computer's view of its phones' texts: syncs the recent conversations
/// when a phone connects, loads older pages on demand, merges what the phone
/// pushes, sends replies, and saves everything so history survives a
/// disconnect. Text content is never logged.
class MessageLibrary {
  MessageLibrary({
    required CacheStore store,
    required Session? Function(String deviceId) sessionFor,
    required this.featureId,
    DateTime Function()? clock,
    this.saveDelay = const Duration(seconds: 1),
  }) : _store = store,
       _sessionFor = sessionFor,
       _clock = clock ?? DateTime.now;

  /// Recent conversations synced first, with names, when a phone connects.
  static const firstPageSize = 30;
  static const conversationPageSize = 30;
  static const messagePageSize = 50;

  static const _requestTimeout = Duration(seconds: 20);
  static const _sendTimeout = Duration(seconds: 75);
  static const _attachmentTimeout = Duration(seconds: 60);

  final String featureId;
  final Duration saveDelay;
  final CacheStore _store;
  final Session? Function(String deviceId) _sessionFor;
  final DateTime Function() _clock;
  final Map<String, MessageCache> _caches = {};
  final Map<String, PhoneState> _phones = {};
  final Map<String, Timer> _saveTimers = {};
  final Set<String> _visible = {};

  /// Phones whose first page was synced since they connected.
  final Set<String> _synced = {};
  final StreamController<LibraryEvent> _events = .broadcast();
  bool _disposed = false;

  Stream<LibraryEvent> get events => _events.stream;

  /// Phones with saved texts or a live connection.
  List<String> get deviceIds => {..._caches.keys, ..._phones.keys}.toList();

  PhoneState phone(String deviceId) =>
      _phones[deviceId] ?? PhoneState(deviceId: deviceId);

  /// The saved texts of [deviceId], empty when there are none.
  MessageCache cache(String deviceId) =>
      _caches.putIfAbsent(deviceId, MessageCache.new);

  bool hasHistory(String deviceId) => !(_caches[deviceId]?.isEmpty ?? true);

  int unreadTotal(String deviceId) => _caches[deviceId]?.unreadTotal ?? 0;

  /// Whether the thread is on screen here, so its new texts need no notice.
  bool isVisible(String deviceId, int threadId) =>
      _visible.contains(_visibleKey(deviceId, threadId));

  void setVisible(String deviceId, int threadId, bool visible) {
    final key = _visibleKey(deviceId, threadId);
    if (visible) {
      _visible.add(key);
      return;
    }

    _visible.remove(key);
  }

  /// Reads every saved phone from disk.
  Future<void> load() async {
    final List<String> saved;
    try {
      saved = await _store.deviceIds();
    } on Object catch (error) {
      printWarning('Listing saved texts failed', error);
      return;
    }

    for (final deviceId in saved) {
      try {
        final contents = await _store.read(deviceId);
        if (contents != null) {
          _caches[deviceId] = MessageCache.decode(contents);
          _emit(LibraryChanged(deviceId));
        }
      } on Object catch (error) {
        printWarning('Reading saved texts failed', error);
      }
    }
  }

  /// Saves pending changes now.
  Future<void> flush() async {
    final pending = [..._saveTimers.keys];
    for (final timer in _saveTimers.values) {
      timer.cancel();
    }

    _saveTimers.clear();
    for (final deviceId in pending) {
      await _save(deviceId);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await flush();
    await _events.close();
  }

  /// A phone that shares its texts connected: ask how it is set up, then
  /// sync its recent conversations.
  Future<void> onPhoneConnected(String deviceId) async {
    _synced.remove(deviceId);
    _setPhone(
      phone(deviceId).copyWith(connected: true, clearStatus: true),
    );
    await refresh(deviceId, resync: false);
  }

  void onPhoneDisconnected(String deviceId) {
    _synced.remove(deviceId);
    _setPhone(
      phone(deviceId).copyWith(
        connected: false,
        clearStatus: true,
        syncing: false,
      ),
    );
  }

  /// The phone pushed its status, such as after Messages was turned on.
  Future<void> onStatus(String deviceId, MessagesStatus status) async {
    final wasReady = phone(deviceId).readiness == .ready;
    _setPhone(
      phone(deviceId).copyWith(
        status: status,
        lastRoundTrip: RoundTrip(ok: true, at: _clock()),
      ),
    );

    if (!wasReady &&
        phone(deviceId).readiness == .ready &&
        !_synced.contains(deviceId)) {
      await _syncFirstPage(deviceId);
    }
  }

  /// The phone pushed new or changed texts.
  void onChanged(String deviceId, MessagesChanged changes) {
    final cache = this.cache(deviceId);
    final added = cache.applyChanges(changes);
    _changed(deviceId);

    for (final message in added) {
      if (message.kind != .MESSAGE_KIND_INBOX || message.read) {
        continue;
      }

      _emit(
        IncomingMessage(
          deviceId,
          message,
          cache.conversation(message.threadId.toInt()),
        ),
      );
    }
  }

  /// Asks the phone how it is set up and syncs the newest conversations,
  /// unless they were synced since it connected and [resync] is false.
  /// Returns false when the phone didn't answer.
  Future<bool> refresh(String deviceId, {bool resync = true}) async {
    final status = await _call(
      deviceId,
      StatusRequest(),
      MessagesStatus.new,
    );
    if (status == null) {
      return false;
    }

    _setPhone(phone(deviceId).copyWith(status: status));
    if (phone(deviceId).readiness != .ready ||
        (!resync && _synced.contains(deviceId))) {
      return true;
    }

    return _syncFirstPage(deviceId);
  }

  Future<bool> loadOlderConversations(String deviceId) async {
    final cache = this.cache(deviceId);
    if (!cache.hasMoreConversations) {
      return true;
    }

    final page = await _call(
      deviceId,
      ListConversations(
        beforeDateMs: Int64(cache.oldestConversationDateMs),
        limit: conversationPageSize,
      ),
      ConversationPage.new,
    );
    if (page == null) {
      return false;
    }

    cache.mergeConversationPage(page, newest: false);
    _changed(deviceId);
    return true;
  }

  Future<bool> loadNewestMessages(String deviceId, int threadId) async {
    final page = await _call(
      deviceId,
      ListMessages(threadId: Int64(threadId), limit: messagePageSize),
      MessagePage.new,
    );
    if (page == null) {
      return false;
    }

    cache(deviceId).mergeMessagePage(threadId, page, newest: true);
    _changed(deviceId);
    return true;
  }

  Future<bool> loadOlderMessages(String deviceId, int threadId) async {
    final cache = this.cache(deviceId);
    if (!cache.hasOlderMessages(threadId)) {
      return true;
    }

    final cursor = cache.olderCursor(threadId);
    final page = await _call(
      deviceId,
      ListMessages(
        threadId: Int64(threadId),
        beforeDateMs: Int64(cursor.beforeDateMs),
        skipIds: cursor.skipIds,
        limit: messagePageSize,
      ),
      MessagePage.new,
    );
    if (page == null) {
      return false;
    }

    cache.mergeMessagePage(threadId, page, newest: cursor.beforeDateMs == 0);
    _changed(deviceId);
    return true;
  }

  /// Sends [text] to the conversation [threadId], then loads the newest
  /// texts so the sent one replaces the pending bubble.
  Future<SendOutcome> send(String deviceId, int threadId, String text) async {
    if (phone(deviceId).readiness != .ready) {
      return .offline;
    }

    final result = await _call(
      deviceId,
      SendText(threadId: Int64(threadId), text: text),
      SendResult.new,
      timeout: _sendTimeout,
    );
    if (result == null) {
      return .offline;
    }

    final outcome = SendOutcome.of(result);
    if (outcome == .sent) {
      await loadNewestMessages(deviceId, threadId);
    }

    return outcome;
  }

  /// Marks [threadId] read here, and on the phone when Android lets it.
  Future<void> markRead(String deviceId, int threadId) async {
    final cache = this.cache(deviceId);
    final unread = cache.conversation(threadId)?.unreadCount ?? 0;
    if (unread == 0) {
      return;
    }

    cache.markRead(threadId);
    _changed(deviceId);

    if (phone(deviceId).readiness == .ready) {
      await _call(
        deviceId,
        MarkRead(threadId: Int64(threadId)),
        MarkReadResult.new,
      );
    }
  }

  /// The full file of an attachment, or null when the phone can't send it.
  Future<AttachmentData?> fetchAttachment(
    String deviceId,
    String messageId,
    String partId,
  ) async {
    final data = await _call(
      deviceId,
      FetchAttachment(messageId: messageId, partId: partId),
      AttachmentData.new,
      timeout: _attachmentTimeout,
    );
    if (data == null || data.data.isEmpty) {
      return null;
    }

    return data;
  }

  /// Deletes the saved texts of [deviceId] from this computer.
  Future<void> forget(String deviceId) async {
    _saveTimers.remove(deviceId)?.cancel();
    _caches.remove(deviceId);
    try {
      await _store.delete(deviceId);
    } on Object catch (error) {
      printWarning('Deleting saved texts failed', error);
    }

    _emit(LibraryChanged(deviceId));
  }

  /// Deletes the saved texts of every phone [trust] has forgotten since:
  /// unpairing a phone takes its texts off this computer too.
  Future<void> forgetUnpaired(TrustStore trust) async {
    final forgotten = {for (final device in trust.forgotten) device.id};
    for (final deviceId in deviceIds) {
      if (forgotten.contains(deviceId) && trust[deviceId] == null) {
        await forget(deviceId);
      }
    }
  }

  Future<void> forgetAll() async {
    for (final deviceId in [..._caches.keys]) {
      await forget(deviceId);
    }
  }

  Future<bool> _syncFirstPage(String deviceId) async {
    if (phone(deviceId).syncing) {
      return true;
    }

    _setPhone(phone(deviceId).copyWith(syncing: true));
    final page = await _call(
      deviceId,
      ListConversations(limit: firstPageSize),
      ConversationPage.new,
    );
    _setPhone(phone(deviceId).copyWith(syncing: false));
    if (page == null) {
      return false;
    }

    _synced.add(deviceId);
    cache(deviceId).mergeConversationPage(page, newest: true);
    _changed(deviceId);
    return true;
  }

  /// Sends [request] and records how the round trip went. Returns null when
  /// the phone is gone, refused or didn't answer.
  Future<T?> _call<T extends GeneratedMessage>(
    String deviceId,
    GeneratedMessage request,
    T Function() create, {
    Duration timeout = _requestTimeout,
  }) async {
    final session = _sessionFor(deviceId);
    if (session == null) {
      return null;
    }

    try {
      final reply = await session.call(
        featureId,
        request,
        create,
        timeout: timeout,
      );
      _recordRoundTrip(deviceId, ok: true);
      return reply;
    } on RemoteErrorException catch (error) {
      printDebug('Messages request to $deviceId refused: ${error.code}');
      _recordRoundTrip(deviceId, ok: true);
      if (error.code == .ERROR_CODE_DENIED) {
        unawaited(_recheckStatus(deviceId));
      }

      return null;
    } on Object catch (error) {
      printWarning('Messages request to $deviceId failed', error);
      _recordRoundTrip(deviceId, ok: false);
      return null;
    }
  }

  /// A refused request means the phone turned Messages off or lost access.
  Future<void> _recheckStatus(String deviceId) async {
    final session = _sessionFor(deviceId);
    if (session == null) {
      return;
    }

    try {
      final status = await session.call(
        featureId,
        StatusRequest(),
        MessagesStatus.new,
        timeout: _requestTimeout,
      );
      _setPhone(phone(deviceId).copyWith(status: status));
    } on Object catch (error) {
      printDebug('Messages status of $deviceId not read: $error');
    }
  }

  void _recordRoundTrip(String deviceId, {required bool ok}) {
    _setPhone(
      phone(deviceId).copyWith(
        lastRoundTrip: RoundTrip(ok: ok, at: _clock()),
      ),
    );
  }

  void _setPhone(PhoneState state) {
    _phones[state.deviceId] = state;
    _emit(LibraryChanged(state.deviceId));
  }

  void _changed(String deviceId) {
    _scheduleSave(deviceId);
    _emit(LibraryChanged(deviceId));
  }

  void _scheduleSave(String deviceId) {
    if (_disposed) {
      return;
    }

    _saveTimers[deviceId]?.cancel();
    _saveTimers[deviceId] = Timer(saveDelay, () {
      _saveTimers.remove(deviceId);
      unawaited(_save(deviceId));
    });
  }

  Future<void> _save(String deviceId) async {
    final cache = _caches[deviceId];
    if (cache == null) {
      return;
    }

    try {
      await _store.write(deviceId, cache.encode());
    } on Object catch (error) {
      printWarning('Saving texts failed', error);
    }
  }

  void _emit(LibraryEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  static String _visibleKey(String deviceId, int threadId) =>
      '$deviceId/$threadId';
}
