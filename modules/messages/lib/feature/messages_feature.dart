import 'dart:async';

import 'package:engine/engine.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/messages.dart';
import 'package:protocol/protocol.dart';

/// The engine side of Messages.
///
/// A device with a [source] (an Android phone) answers paired computers'
/// requests for its conversations and texts, sends their replies, and pushes
/// texts that change while they are connected. Every other device keeps a
/// [library] of its phones' texts, saved in a [CacheStore].
class MessagesFeature extends Feature {
  MessagesFeature({
    this.source,
    CacheStore? cacheStore,
    DateTime Function()? clock,
  }) : _cacheStore = cacheStore ?? MemoryCacheStore(),
       _clock = clock ?? DateTime.now;

  static const featureId = 'messages';

  /// Flag of a device whose texts can be read: a phone.
  static const sourceFlag = 'source';

  /// Flag of a device that reads a phone's texts: a computer.
  static const receiveFlag = 'receive';

  final SmsSource? source;
  final CacheStore _cacheStore;
  final DateTime Function() _clock;

  late final MessagesSettings settings = MessagesSettings(host.settings);

  /// The phone side, when this device has a [source].
  late final SourceService? sourceService = switch (source) {
    final SmsSource sms => SourceService(
      source: sms,
      settings: () => settings,
      receivers: () => _sessionsWith(receiveFlag),
      featureId: featureId,
      clock: _clock,
    ),
    null => null,
  };

  /// The computer side: phones' texts, synced and saved.
  late final MessageLibrary library = MessageLibrary(
    store: _cacheStore,
    sessionFor: host.sessionFor,
    featureId: featureId,
    clock: _clock,
  );

  @override
  String get id => featureId;

  @override
  List<String> get flags => switch (isSource) {
    true => const [sourceFlag],
    false => const [receiveFlag],
  };

  bool get isSource => source != null;

  /// Whether [session]'s device shares its texts.
  static bool isPhone(Session session) => _has(session, sourceFlag);

  @override
  Future<void> onStart() async {
    if (sourceService case final service?) {
      await service.start();
      return;
    }

    await library.load();
  }

  @override
  Future<void> stop() async {
    await sourceService?.stop();
    await library.dispose();
  }

  @override
  void onSessionOpened(Session session) {
    if (sourceService case final service? when _has(session, receiveFlag)) {
      unawaited(service.onReceiverConnected(session));
      return;
    }

    if (!isSource && _has(session, sourceFlag)) {
      unawaited(library.onPhoneConnected(session.remoteDeviceId));
    }
  }

  @override
  void onSessionClosed(Session session) {
    if (sourceService case final service? when _has(session, receiveFlag)) {
      unawaited(service.onReceiverDisconnected());
      return;
    }

    if (!isSource && _has(session, sourceFlag)) {
      library.onPhoneDisconnected(session.remoteDeviceId);
    }
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (sourceService case final service?) {
      return service.handle(session, envelope);
    }

    final deviceId = session.remoteDeviceId;
    if (payloadOf(envelope, MessagesStatus.new) case final status?) {
      await library.onStatus(deviceId, status);
      return null;
    }

    if (payloadOf(envelope, MessagesChanged.new) case final changes?) {
      library.onChanged(deviceId, changes);
      return null;
    }

    if (envelope.expectsReply) {
      await session.replyError(envelope, .ERROR_CODE_UNSUPPORTED);
    }

    return null;
  }

  List<Session> _sessionsWith(String flag) => [
    for (final session in host.sessions)
      if (_has(session, flag)) session,
  ];

  static bool _has(Session session, String flag) =>
      session.remoteFeature(featureId)?.flags.contains(flag) ?? false;
}
