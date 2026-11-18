import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/change_tracker.dart';
import 'package:messages/services/sms_source.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/messages.dart';
import 'package:protocol/protocol.dart';

/// The phone's side of Messages: answers computers' requests from the SMS
/// providers, and while a computer is connected, pushes texts that change.
/// Text content is never logged.
class SourceService {
  SourceService({
    required this.source,
    required MessagesSettings Function() settings,
    required List<Session> Function() receivers,
    required this.featureId,
    DateTime Function()? clock,
  }) : _settings = settings,
       _receivers = receivers,
       _clock = clock ?? DateTime.now;

  static const defaultConversationPage = 30;
  static const maxConversationPage = 100;
  static const defaultMessagePage = 50;
  static const maxMessagePage = 200;
  static const _recentLimit = 100;
  static const _threadPeek = 5;

  final SmsSource source;
  final String featureId;
  final MessagesSettings Function() _settings;
  final List<Session> Function() _receivers;
  final DateTime Function() _clock;
  final ChangeTracker _tracker = ChangeTracker();
  final StreamController<void> _changes = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  SmsAccess _access = SmsAccess.none;
  bool _watching = false;

  // Checks run one at a time, so two bursts never push the same text twice.
  Future<void> _queue = Future.value();
  bool _checkQueued = false;

  /// What the phone lets Ferret do, as last read.
  SmsAccess get access => _access;

  MessagesSettings get settings => _settings();

  /// Fires when [access], the settings or watching change.
  Stream<void> get changes => _changes.stream;

  bool get isWatching => _watching;

  MessagesStatus get status => MessagesStatus(
    enabled: settings.enabled,
    smsAccess: _access.canRead,
    sendAccess: _access.canSend,
    contactsAccess: _access.canReadContacts,
  );

  bool get _serving => settings.enabled && _access.canRead;

  Future<void> start() async {
    _subscriptions
      ..add(
        settings.changes.listen((_) => unawaited(_onStateChanged())),
      )
      ..add(source.changes.listen((_) => _scheduleCheck()));
    await refreshAccess();
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await _setWatching(false);
    await _changes.close();
  }

  /// Reads access again, such as when the app comes back from Settings, and
  /// tells connected computers when it changed.
  Future<SmsAccess> refreshAccess() async {
    try {
      _access = await source.access();
    } on Object catch (error) {
      printWarning('Reading SMS access failed', error);
      _access = SmsAccess.none;
    }

    await _onStateChanged();
    return _access;
  }

  /// Shows the system permission dialog.
  Future<SmsAccess> requestAccess() async {
    try {
      _access = await source.requestAccess();
    } on Object catch (error) {
      printWarning('Asking for SMS access failed', error);
    }

    await _onStateChanged();
    return _access;
  }

  Future<bool> openAppSettings() async {
    try {
      return await source.openAppSettings();
    } on Object catch (error) {
      printWarning('Opening app settings failed', error);
      return false;
    }
  }

  Future<void> onReceiverConnected(Session session) async {
    await _sendTo(session, status);
    await _updateWatching();
  }

  Future<void> onReceiverDisconnected() => _updateWatching();

  /// Answers a computer's request, or returns null after replying with an
  /// error.
  Future<GeneratedMessage?> handle(Session session, Envelope envelope) async {
    if (payloadOf(envelope, StatusRequest.new) != null) {
      return status;
    }

    if (!_serving) {
      await _replyError(session, envelope, .ERROR_CODE_DENIED);
      return null;
    }

    try {
      return await _answer(envelope) ?? await _unsupported(session, envelope);
    } on Object catch (error) {
      printWarning('Answering a messages request failed', error);
      await _replyError(session, envelope, .ERROR_CODE_INTERNAL);
      return null;
    }
  }

  Future<GeneratedMessage?> _answer(Envelope envelope) async {
    if (payloadOf(envelope, ListConversations.new) case final request?) {
      return source.listConversations(
        beforeDateMs: request.beforeDateMs.toInt(),
        limit: _clamp(
          request.limit,
          defaultConversationPage,
          maxConversationPage,
        ),
      );
    }

    if (payloadOf(envelope, ListMessages.new) case final request?) {
      final page = await source.listMessages(
        request.threadId.toInt(),
        beforeDateMs: request.beforeDateMs.toInt(),
        skipIds: request.skipIds,
        limit: _clamp(request.limit, defaultMessagePage, maxMessagePage),
      );
      return page..threadId = request.threadId;
    }

    if (payloadOf(envelope, FetchAttachment.new) case final request?) {
      final data = await source.fetchAttachment(
        request.messageId,
        request.partId,
      );
      return data ?? AttachmentData();
    }

    if (payloadOf(envelope, SendText.new) case final request?) {
      return _send(request);
    }

    if (payloadOf(envelope, MarkRead.new) case final request?) {
      final applied = await source.markRead(request.threadId.toInt());
      return MarkReadResult(applied: applied);
    }

    return null;
  }

  Future<SendResult> _send(SendText request) async {
    if (!_access.canSend) {
      return SendResult(failure: .SEND_FAILURE_NO_ACCESS);
    }

    if (request.text.trim().isEmpty) {
      return SendResult(failure: .SEND_FAILURE_NO_RECIPIENT);
    }

    final result = await source.send(request);
    _scheduleCheck();
    return result;
  }

  Future<GeneratedMessage?> _unsupported(
    Session session,
    Envelope envelope,
  ) async {
    await _replyError(session, envelope, .ERROR_CODE_UNSUPPORTED);
    return null;
  }

  Future<void> _replyError(
    Session session,
    Envelope envelope,
    ErrorCode code,
  ) async {
    if (!envelope.expectsReply) {
      return;
    }

    try {
      await session.replyError(envelope, code);
    } on Object catch (error) {
      printDebug('Messages error reply not sent: $error');
    }
  }

  Future<void> _onStateChanged() async {
    for (final session in _receivers()) {
      await _sendTo(session, status);
    }

    await _updateWatching();
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  /// Watching costs battery, so it runs only while a computer listens.
  Future<void> _updateWatching() =>
      _setWatching(_serving && _receivers().isNotEmpty);

  Future<void> _setWatching(bool watch) async {
    if (watch == _watching) {
      return;
    }

    _watching = watch;
    if (!watch) {
      await _guard(source.stopWatching, 'Stopping the SMS watcher failed');
      return;
    }

    await _baseline();
    await _guard(source.startWatching, 'Starting the SMS watcher failed');
  }

  Future<void> _baseline() async {
    final nowMs = _clock().millisecondsSinceEpoch;
    try {
      final recent = await source.recentMessages(
        sinceDateMs: nowMs - ChangeTracker.lookback.inMilliseconds,
        limit: _recentLimit,
      );
      final top = await source.listConversations(
        limit: ChangeTracker.watchedConversations,
      );
      _tracker.baseline(recent, top.conversations, nowMs);
    } on Object catch (error) {
      printWarning('Reading recent texts failed', error);
      _tracker.baseline(const [], const [], nowMs);
    }
  }

  void _scheduleCheck() {
    if (!_watching || _checkQueued) {
      return;
    }

    _checkQueued = true;
    _queue = _queue.then((_) async {
      _checkQueued = false;
      try {
        await _check();
      } on Object catch (error) {
        printWarning('Checking for new texts failed', error);
      }
    });
  }

  /// Finds new and changed texts and conversations and pushes them. Texts
  /// that arrive late with an older date (such as a downloaded MMS) are found
  /// through their conversation's new last date.
  Future<void> _check() async {
    if (!_watching) {
      return;
    }

    final recent = await source.recentMessages(
      sinceDateMs: _tracker.sinceMs,
      limit: _recentLimit,
    );
    final top = await source.listConversations(
      limit: ChangeTracker.watchedConversations,
    );

    final candidates = [...recent];
    for (final conversation in top.conversations) {
      final threadId = conversation.threadId.toInt();
      final previousDate = _tracker.lastDateOf(threadId);
      final lastDate = conversation.lastDateMs.toInt();
      if (previousDate != null && lastDate <= previousDate) {
        continue;
      }

      final peek = await source.listMessages(threadId, limit: _threadPeek);
      candidates.addAll(
        peek.messages.where(
          (message) =>
              _tracker.knows(message.id) ||
              message.dateMs.toInt() > (previousDate ?? 0),
        ),
      );
    }

    final messages = _tracker.changedMessages(candidates);
    final conversations = _tracker.changedConversations(top.conversations);
    final known = {
      for (final conversation in conversations) conversation.threadId.toInt(),
    };
    final missing = {
      for (final message in messages)
        if (!known.contains(message.threadId.toInt())) message.threadId.toInt(),
    };
    if (missing.isNotEmpty) {
      conversations.addAll(await source.conversationsById(missing.toList()));
    }

    if (messages.isEmpty && conversations.isEmpty) {
      return;
    }

    final push = MessagesChanged(
      messages: messages,
      conversations: conversations,
    );
    for (final session in _receivers()) {
      await _sendTo(session, push);
    }
  }

  Future<void> _sendTo(Session session, GeneratedMessage message) async {
    try {
      await session.send(featureId, message);
    } on Object catch (error) {
      printWarning('Messages push to ${session.remoteDeviceId} failed', error);
    }
  }

  Future<void> _guard(Future<void> Function() action, String failure) async {
    try {
      await action();
    } on Object catch (error) {
      printWarning(failure, error);
    }
  }

  static int _clamp(int requested, int fallback, int max) {
    if (requested <= 0) {
      return fallback;
    }

    if (requested > max) {
      return max;
    }

    return requested;
  }
}
