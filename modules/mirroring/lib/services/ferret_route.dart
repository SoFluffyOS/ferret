import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:mirroring/services/ferret_feed.dart';
import 'package:mirroring/services/mirror_protocol.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';
import 'package:protocol/protocol.dart';

/// Ferret's own way to a screen: asks a paired phone over its session,
/// where the owner answers Android's prompt, and takes the frames the
/// phone sends back. One feed per phone.
class FerretRoute implements MirrorRoute {
  FerretRoute({
    required FeatureHost host,
    required String featureId,
    DateTime Function()? clock,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _host = host,
       _featureId = featureId,
       _clock = clock ?? DateTime.now;

  static const routeId = 'ferret';

  static const _strayNoticeGap = Duration(seconds: 1);

  /// How long the phone has to answer the request itself.
  final Duration requestTimeout;

  final FeatureHost _host;
  final String _featureId;
  final DateTime Function() _clock;
  final Map<String, FerretFeed> _feeds = {};
  final Map<String, DateTime> _strayNoticeAt = {};

  @override
  String get id => routeId;

  @override
  Future<RouteStatus> status() async => const RouteReady();

  /// The connected phones that offer their screen.
  @override
  Stream<List<MirrorTarget>> get targets async* {
    yield _targetsNow();
    await for (final _ in _host.sessionChanges) {
      yield _targetsNow();
    }
  }

  /// [deviceId] as a target, connected or not, under the name it is known
  /// by here.
  MirrorTarget targetFor(String deviceId) => MirrorTarget(
    routeId: routeId,
    id: deviceId,
    name: _host.displayNameOf(deviceId),
    ferretDeviceId: deviceId,
    wireless: true,
  );

  /// Whether [deviceId] is connected and offers its screen right now.
  bool isConnected(String deviceId) {
    final session = _host.sessionFor(deviceId);
    return session != null && canShow(session);
  }

  /// Whether [session]'s device offers its screen.
  bool canShow(Session session) =>
      session
          .remoteFeature(_featureId)
          ?.flags
          .contains(MirrorProtocol.shareFlag) ??
      false;

  /// Asks the phone. The feed that comes back already knows the phone's
  /// first answer: it waits for its owner, or it ended with why not.
  @override
  Future<MirrorFeed> open(MirrorTarget target, FeedOptions options) async {
    final deviceId = target.id;
    final session = _host.sessionFor(deviceId);
    final feed = FerretFeed(
      target: target,
      send: (message) => _send(deviceId, message),
      clock: _clock,
      onEnded: _forget,
      wantsSound: options.audio,
    );
    if (session == null) {
      feed.end(.notConnected);
      return feed;
    }

    _feeds[deviceId] = feed;
    final longSide = MirrorProtocol.sideFor(
      options.maxSize,
      MirrorProtocol.maxLongSide,
    );
    final Envelope reply;
    try {
      reply = await session.request(
        _featureId,
        StartRequest(
          version: MirrorProtocol.version,
          codecs: options.codecs.map(MirrorProtocol.toProto),
          maxWidth: longSide,
          maxHeight: longSide,
          maxFps: options.maxFps,
          audioCodecs: options.audioCodecs.map(MirrorProtocol.audioToProto),
        ),
        timeout: requestTimeout,
      );
    } on SessionClosedException {
      feed.end(.lostConnection);
      return feed;
    } on Object catch (error) {
      printWarning('Asking $deviceId for its screen failed', error);
      feed.end(.noAnswer);
      return feed;
    }

    if (payloadOf(reply, StartPending.new) case final pending?) {
      feed.waiting(Duration(seconds: pending.timeoutSeconds));
      return feed;
    }

    if (payloadOf(reply, StartDeny.new) case final deny?) {
      feed.end(FerretFeed.endOfDeny(deny.reason));
      return feed;
    }

    feed.end(.noAnswer);
    return feed;
  }

  void onAccept(Session session, StartAccept accept) {
    final accepted = _feeds[session.remoteDeviceId]?.onAccept(accept) ?? false;
    if (!accepted) {
      _answerStray(session);
    }
  }

  void onDeny(Session session, StartDeny deny) =>
      _feeds[session.remoteDeviceId]?.onDeny(deny.reason);

  void onConfig(Session session, StreamConfig config) =>
      _feeds[session.remoteDeviceId]?.onConfig(config);

  void onFrame(Session session, Frame frame) {
    final watched = _feeds[session.remoteDeviceId]?.onFrame(frame) ?? false;
    if (!watched) {
      _answerStray(session);
    }
  }

  void onAudioConfig(Session session, AudioConfig config) =>
      _feeds[session.remoteDeviceId]?.onAudioConfig(config);

  void onAudioFrame(Session session, AudioFrame frame) {
    final heard = _feeds[session.remoteDeviceId]?.onAudioFrame(frame) ?? false;
    if (!heard) {
      _answerStray(session);
    }
  }

  void onAudioEnded(Session session) =>
      _feeds[session.remoteDeviceId]?.onAudioEnded();

  void onControlState(Session session, ControlState state) =>
      _feeds[session.remoteDeviceId]?.onControlState(state);

  void onSourceState(Session session, SourceState state) =>
      _feeds[session.remoteDeviceId]?.onSourceState(state);

  void onStats(Session session, Stats stats) =>
      _feeds[session.remoteDeviceId]?.onStats(stats);

  void onStop(Session session, Stop stop) =>
      _feeds[session.remoteDeviceId]?.onStop(stop.reason);

  void onSessionClosed(String deviceId) =>
      _feeds[deviceId]?.end(.lostConnection);

  @override
  Future<void> dispose() async {
    for (final feed in List.of(_feeds.values)) {
      await feed.stop();
    }
  }

  List<MirrorTarget> _targetsNow() => [
    for (final session in _host.sessions)
      if (canShow(session)) targetFor(session.remoteDeviceId),
  ];

  void _forget(FerretFeed feed) {
    final deviceId = feed.target.id;
    if (identical(_feeds[deviceId], feed)) {
      _feeds.remove(deviceId);
    }
  }

  /// Frames from a phone this computer isn't watching: tells it to stop,
  /// at most once a second.
  void _answerStray(Session session) {
    final deviceId = session.remoteDeviceId;
    final now = _clock();
    final last = _strayNoticeAt[deviceId];
    if (last != null && now.difference(last) < _strayNoticeGap) {
      return;
    }

    _strayNoticeAt[deviceId] = now;
    unawaited(_send(deviceId, Stop(reason: .STOP_REASON_NOT_MIRRORING)));
  }

  Future<void> _send(String deviceId, GeneratedMessage message) async {
    final session = _host.sessionFor(deviceId);
    if (session == null) {
      return;
    }

    try {
      await session.send(_featureId, message);
    } on Object catch (error) {
      printWarning('Mirroring message to $deviceId failed', error);
    }
  }
}
