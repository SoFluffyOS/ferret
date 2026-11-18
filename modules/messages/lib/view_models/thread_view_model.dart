import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/services.dart';
import 'package:protocol/messages.dart';

/// Why the composer can't send right now.
enum ComposerBlock {
  none,

  /// The phone isn't connected or ready.
  offline,

  /// The phone doesn't let Ferret send SMS.
  noSend,

  /// Group conversations need MMS, which only the phone's app can send.
  group,
}

/// One conversation on a computer: saved texts at once, the newest page from
/// the phone, older pages on scroll, and replies with a pending bubble until
/// the phone confirms.
class ThreadViewModel extends ChangeNotifier {
  ThreadViewModel({
    required MessageLibrary library,
    required this.deviceId,
    required this.threadId,
    void Function()? onOpened,
    DateTime Function()? clock,
  }) : _library = library,
       _onOpened = onOpened,
       _clock = clock ?? DateTime.now {
    _subscription = library.events
        .where((event) => event.deviceId == deviceId)
        .listen(_onLibraryEvent);
    library.setVisible(deviceId, threadId, true);
    unawaited(open());
  }

  final String deviceId;
  final int threadId;
  final MessageLibrary _library;
  final void Function()? _onOpened;
  final DateTime Function() _clock;
  late final StreamSubscription<LibraryEvent> _subscription;

  final List<PendingMessage> _pending = [];
  int _nextPendingId = 0;
  bool _loadingNewest = false;
  bool _loadingOlder = false;
  bool _loadFailed = false;
  bool _wasReady = false;
  bool _disposed = false;

  PhoneState get phone => _library.phone(deviceId);

  Conversation? get conversation =>
      _library.cache(deviceId).conversation(threadId);

  /// Oldest first.
  List<Message> get messages => _library.cache(deviceId).messages(threadId);

  /// Replies typed here and not confirmed yet, oldest first.
  List<PendingMessage> get pending => List.unmodifiable(_pending);

  bool get loadingNewest => _loadingNewest;

  bool get loadingOlder => _loadingOlder;

  bool get loadFailed => _loadFailed;

  bool get hasOlder => _library.cache(deviceId).hasOlderMessages(threadId);

  ComposerBlock get composerBlock {
    if (phone.readiness != .ready) {
      return .offline;
    }

    if (conversation?.isGroup ?? false) {
      return .group;
    }

    if (!phone.canSend) {
      return .noSend;
    }

    return .none;
  }

  /// Shows the newest texts and marks the conversation read.
  Future<void> open() async {
    _onOpened?.call();
    await _library.markRead(deviceId, threadId);
    await loadNewest();
  }

  Future<void> loadNewest() async {
    if (_loadingNewest || phone.readiness != .ready) {
      return;
    }

    _wasReady = true;
    _loadingNewest = true;
    _notify();

    final ok = await _library.loadNewestMessages(deviceId, threadId);
    _loadingNewest = false;
    _loadFailed = !ok;
    _notify();
  }

  Future<void> loadOlder() async {
    if (_loadingOlder || !hasOlder || phone.readiness != .ready) {
      return;
    }

    _loadingOlder = true;
    _notify();

    final ok = await _library.loadOlderMessages(deviceId, threadId);
    _loadingOlder = false;
    _loadFailed = !ok;
    _notify();
  }

  /// Sends [text]. Returns false when there was nothing to send or the
  /// composer is blocked, so the field keeps the text.
  Future<bool> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || composerBlock != .none) {
      return false;
    }

    final pending = PendingMessage(
      id: 'local:${_nextPendingId++}',
      text: trimmed,
      at: _clock(),
    );
    _pending.add(pending);
    _notify();

    unawaited(_deliver(pending));
    return true;
  }

  Future<void> retry(PendingMessage message) async {
    final index = _pending.indexWhere((item) => item.id == message.id);
    if (index < 0 || composerBlock != .none) {
      return;
    }

    _pending[index] = message.withOutcome(null);
    _notify();
    await _deliver(_pending[index]);
  }

  void discard(PendingMessage message) {
    _pending.removeWhere((item) => item.id == message.id);
    _notify();
  }

  /// The full picture of [attachment], or null when the phone can't send it.
  Future<Uint8List?> fullImage(Message message, Attachment attachment) async {
    final data = await _library.fetchAttachment(
      deviceId,
      message.id,
      attachment.partId,
    );
    if (data == null) {
      return null;
    }

    return Uint8List.fromList(data.data);
  }

  @override
  void dispose() {
    _disposed = true;
    _library.setVisible(deviceId, threadId, false);
    unawaited(_subscription.cancel());
    super.dispose();
  }

  Future<void> _deliver(PendingMessage message) async {
    final outcome = await _library.send(deviceId, threadId, message.text);
    final index = _pending.indexWhere((item) => item.id == message.id);
    if (index < 0) {
      return;
    }

    if (outcome == .sent) {
      _pending.removeAt(index);
      _notify();
      return;
    }

    _pending[index] = message.withOutcome(outcome);
    _notify();
  }

  void _onLibraryEvent(LibraryEvent event) {
    final ready = phone.readiness == .ready;
    if (ready && !_wasReady) {
      unawaited(loadNewest());
    }

    if (!ready) {
      _wasReady = false;
    }

    if ((conversation?.unreadCount ?? 0) > 0) {
      unawaited(_library.markRead(deviceId, threadId));
    }

    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
