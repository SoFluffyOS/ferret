import 'dart:async';

import 'package:ferret_messages/src/messages.g.dart';
import 'package:flutter/foundation.dart';

/// SMS and MMS on Android: read conversations and messages with contact
/// names and photos, watch for changes, send texts, and manage the
/// permissions.
///
/// Only Android implements it; check [isSupported] first.
class FerretMessages {
  FerretMessages({MessagesHostApi? hostApi})
    : _hostApi = hostApi ?? MessagesHostApi();

  final MessagesHostApi _hostApi;

  // One handler per Flutter engine receives the platform's events, so every
  // instance shares it.
  static final StreamController<void> _changes = .broadcast(
    onListen: () => MessagesFlutterApi.setUp(_ChangeRelay(_changes)),
    onCancel: () => MessagesFlutterApi.setUp(null),
  );

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Fires when messages change on the phone, after [startWatching].
  Stream<void> get changes => _changes.stream;

  Future<PlatformAccess> access() => _hostApi.access();

  /// Shows Android's permission dialog. Needs the app in the foreground.
  Future<PlatformAccess> requestAccess() => _hostApi.requestAccess();

  Future<bool> openAppSettings() => _hostApi.openAppSettings();

  Future<PlatformConversationPage> listConversations({
    int beforeDateMs = 0,
    required int limit,
  }) => _hostApi.listConversations(beforeDateMs, limit);

  Future<List<PlatformConversation>> conversationsById(List<int> threadIds) =>
      _hostApi.conversationsById(threadIds);

  Future<PlatformMessagePage> listMessages(
    int threadId, {
    int beforeDateMs = 0,
    List<String> skipIds = const [],
    required int limit,
  }) => _hostApi.listMessages(threadId, beforeDateMs, skipIds, limit);

  Future<List<PlatformMessage>> recentMessages({
    required int sinceDateMs,
    required int limit,
  }) => _hostApi.recentMessages(sinceDateMs, limit);

  Future<PlatformAttachmentData?> fetchAttachment(
    String messageId,
    String partId,
  ) => _hostApi.fetchAttachment(messageId, partId);

  /// Sends [text] to the conversation [threadId], or to [addresses] when it
  /// is 0.
  Future<PlatformSendResult> send({
    int threadId = 0,
    List<String> addresses = const [],
    required String text,
  }) => _hostApi.send(threadId, addresses, text);

  Future<bool> markRead(int threadId) => _hostApi.markRead(threadId);

  Future<void> startWatching() => _hostApi.startWatching();

  Future<void> stopWatching() => _hostApi.stopWatching();
}

class _ChangeRelay implements MessagesFlutterApi {
  _ChangeRelay(this._sink);

  final StreamController<void> _sink;

  @override
  void onChanged() => _sink.add(null);
}
