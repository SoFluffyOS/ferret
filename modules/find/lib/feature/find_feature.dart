import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/models/models.dart';
import 'package:find/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/find.dart';
import 'package:protocol/protocol.dart';

/// Rings a lost device, and rings this one when another device asks. Works
/// on silent and Do Not Disturb when the person allowed it, stops on "Found
/// it", and tells every device that asked how it ended.
class FindFeature extends Feature {
  FindFeature({
    FindPlatform Function()? platform,
    RingTexts Function(String requesterName)? texts,
    DateTime Function()? clock,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _createPlatform = platform ?? FindPlatform.current,
       _texts = texts,
       _clock = clock ?? DateTime.now;

  static const featureId = 'find';

  /// Flag in [FeatureSupport]: this device can ring.
  static const ringFlag = 'ring';

  /// A ring this device asked for counts as over this long after it should
  /// have ended, in case the stop message got lost.
  static const _endGrace = Duration(seconds: 5);

  /// How long to wait for another device to answer.
  final Duration requestTimeout;

  final FindPlatform Function() _createPlatform;
  final RingTexts Function(String requesterName)? _texts;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final Map<String, OutgoingRing> _outgoing = {};
  final Map<String, Timer> _outgoingTimers = {};
  final Map<String, RemoteRingInfo> _remote = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];

  late final FindPlatform _platform;
  late final RingController _controller;
  RingInfo? _lastSentInfo;

  /// The device whose request stopped the ring, which already got a reply.
  String? _stoppedBy;

  @override
  String get id => featureId;

  @override
  List<String> get flags => const [ringFlag];

  FindSettings get settings => FindSettings(host.settings);

  /// This device ringing, or idle.
  LocalRing get localRing => _controller.current;

  RingAbilities get abilities => _controller.abilities;

  /// Rings this device asked for, newest first.
  List<OutgoingRing> get outgoing {
    final rings = _outgoing.values.toList()
      ..sort((first, second) => second.startedAt.compareTo(first.startedAt));
    return rings;
  }

  OutgoingRing? outgoingFor(String deviceId) => _outgoing[deviceId];

  RemoteRingInfo? remoteInfo(String deviceId) => _remote[deviceId];

  /// What this device tells others about ringing it.
  RingInfo get localInfo {
    final abilities = _controller.abilities;
    final ringOnSilent = settings.ringOnSilent;

    return RingInfo(
      ringing: localRing.isRinging,
      ringsWhenSilent: ringOnSilent && abilities.canRingWhenSilent,
      needsAppOpen: !abilities.ringsInBackground,
      needsPermission: ringOnSilent && abilities.missingDndAccess,
    );
  }

  /// Ringing through Do Not Disturb worked before and the system access for
  /// it is gone now. False when it was simply never allowed.
  bool get lostDndAccess =>
      settings.ringOnSilent &&
      abilities.missingDndAccess &&
      settings.hadDndAccess;

  /// Fires when a ring, a device's answer, the abilities or a setting change.
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> onStart() async {
    _platform = _createPlatform();
    _controller = RingController(
      platform: _platform,
      settings: settings,
      texts: _texts,
      clock: _clock,
    );
    _subscriptions
      ..add(_controller.changes.listen(_onLocalRing))
      ..add(settings.changes.listen((_) => _onLocalInfoChanged()));
    await _controller.start();
    _rememberDndAccess();
    _lastSentInfo = localInfo;
  }

  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    for (final timer in _outgoingTimers.values) {
      timer.cancel();
    }

    _outgoingTimers.clear();
    await _controller.dispose();
  }

  @override
  void onSessionOpened(Session session) {
    if (session.supports(featureId)) {
      unawaited(_fetchInfo(session));
    }
  }

  @override
  void onSessionClosed(Session session) {
    final deviceId = session.remoteDeviceId;
    _remote.remove(deviceId);
    final ring = _outgoing[deviceId];
    if (ring != null && ring.isActive) {
      _updateOutgoing(ring.copyWith(phase: .lostConnection));
    }

    _emit();
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (payloadOf(envelope, RingRequest.new) case final request?) {
      return _onRingRequest(session, request);
    }

    if (payloadOf(envelope, StopRingRequest.new) != null) {
      if (localRing.isRinging) {
        _stoppedBy = session.remoteDeviceId;
      }

      final ring = await _controller.stop(.STOP_REASON_STOPPED_REMOTELY);
      return _statusOf(ring);
    }

    if (payloadOf(envelope, GetRingInfo.new) != null) {
      return localInfo;
    }

    if (payloadOf(envelope, RingStatus.new) case final status?) {
      _onRemoteStatus(session.remoteDeviceId, status);
      return null;
    }

    if (payloadOf(envelope, RingInfo.new) case final info?) {
      _remote[session.remoteDeviceId] = RemoteRingInfo.answered(info);
      _emit();
    }

    return null;
  }

  /// Asks [deviceId] to ring. The result is in [outgoingFor] and [changes].
  Future<OutgoingRing> ring(String deviceId) async {
    final session = host.sessionFor(deviceId);
    final ring = OutgoingRing(
      deviceId: deviceId,
      deviceName: _nameOf(deviceId, session),
      phase: .requesting,
      startedAt: _clock(),
    );

    if (session == null) {
      return _updateOutgoing(ring.copyWith(phase: .unreachable));
    }

    if (!session.supports(featureId)) {
      return _updateOutgoing(ring.copyWith(phase: .notSupported));
    }

    _updateOutgoing(ring);
    final request = RingRequest(
      durationSeconds: RingController.defaultDuration.inSeconds,
      overrideSilent: true,
    );
    try {
      final status = await session.call(
        featureId,
        request,
        RingStatus.new,
        timeout: requestTimeout,
      );
      return _updateOutgoing(_applyStatus(ring, status));
    } on RemoteErrorException catch (error) {
      printWarning('Ringing $deviceId failed', error);
      final phase = switch (error.code) {
        .ERROR_CODE_UNSUPPORTED => OutgoingPhase.notSupported,
        _ => OutgoingPhase.unreachable,
      };
      return _updateOutgoing(ring.copyWith(phase: phase));
    } on Object catch (error) {
      printWarning('Ringing $deviceId failed', error);
      return _updateOutgoing(ring.copyWith(phase: .unreachable));
    }
  }

  /// Asks [deviceId] to stop ringing.
  Future<void> stopRinging(String deviceId) async {
    final ring = _outgoing[deviceId];
    if (ring == null || !ring.isActive) {
      return;
    }

    final session = host.sessionFor(deviceId);
    if (session == null) {
      _updateOutgoing(ring.copyWith(phase: .lostConnection));
      return;
    }

    try {
      await session.call(
        featureId,
        StopRingRequest(),
        RingStatus.new,
        timeout: requestTimeout,
      );
      _updateOutgoing(ring.copyWith(phase: .stoppedHere));
    } on Object catch (error) {
      printWarning('Stopping the ring on $deviceId failed', error);
      _updateOutgoing(ring.copyWith(phase: .lostConnection));
    }
  }

  /// Forgets a ring that ended, so the card no longer shows it.
  void dismiss(String deviceId) {
    final ring = _outgoing[deviceId];
    if (ring == null || ring.isActive) {
      return;
    }

    _outgoing.remove(deviceId);
    _outgoingTimers.remove(deviceId)?.cancel();
    _emit();
  }

  /// Someone found this device: stops ringing it.
  Future<void> foundIt() async {
    await _controller.stop(.STOP_REASON_FOUND);
  }

  /// Rings this device briefly, to check it is loud enough.
  Future<LocalRing> testRing() => _controller.ring(
    requesterId: host.identity.deviceId,
    requesterName: host.localDevice.name,
    duration: RingController.minDuration,
  );

  /// Reads the permissions again, such as when the app comes back from
  /// system settings, and tells the other devices if that changed something.
  Future<RingAbilities> refreshAbilities() async {
    final abilities = await _controller.refreshAbilities();
    _onLocalInfoChanged();
    return abilities;
  }

  /// Asks [deviceId] again how ringing it would go, after it didn't answer
  /// or couldn't ring.
  Future<void> checkAgain(String deviceId) async {
    final session = host.sessionFor(deviceId);
    if (session == null || !session.supports(featureId)) {
      return;
    }

    await _fetchInfo(session);
  }

  Future<void> openDndAccessSettings() => _platform.openDndAccessSettings();

  Future<void> openFullScreenSettings() => _platform.openFullScreenSettings();

  Future<RingStatus> _onRingRequest(
    Session session,
    RingRequest request,
  ) async {
    final duration = switch (request.durationSeconds) {
      0 => null,
      final seconds => Duration(seconds: seconds),
    };
    final ring = await _controller.ring(
      requesterId: session.remoteDeviceId,
      requesterName: _nameOf(session.remoteDeviceId, session),
      duration: duration,
      overrideSilent: request.overrideSilent,
    );
    return _statusOf(ring);
  }

  RingStatus _statusOf(LocalRing ring) {
    if (!ring.isRinging) {
      return RingStatus(state: .RING_STATE_STOPPED, reason: ring.reason);
    }

    final remaining = switch (ring.endsAt) {
      final endsAt? => endsAt.difference(_clock()).inMilliseconds,
      null => 0,
    };
    return RingStatus(
      state: .RING_STATE_RINGING,
      remainingMs: switch (remaining > 0) {
        true => remaining,
        false => 0,
      },
      muted: ring.muted,
    );
  }

  /// Tells each device that asked, except the one that stopped it, how the
  /// ring ended.
  void _onLocalRing(LocalRing ring) {
    _onLocalInfoChanged();
    if (ring.phase != .stopped) {
      return;
    }

    final stoppedBy = _stoppedBy;
    _stoppedBy = null;
    final status = _statusOf(ring);
    for (final requesterId in ring.requesterIds) {
      final session = host.sessionFor(requesterId);
      if (requesterId == stoppedBy || session == null) {
        continue;
      }

      unawaited(
        session.send(featureId, status).catchError((Object error) {
          printWarning('Ring status to $requesterId failed', error);
        }),
      );
    }
  }

  void _onRemoteStatus(String deviceId, RingStatus status) {
    final ring = _outgoing[deviceId];
    if (ring == null || !ring.isActive) {
      return;
    }

    _updateOutgoing(_applyStatus(ring, status));
  }

  OutgoingRing _applyStatus(OutgoingRing ring, RingStatus status) {
    if (status.state == .RING_STATE_RINGING) {
      return ring.copyWith(
        phase: .ringing,
        endsAt: _clock().add(Duration(milliseconds: status.remainingMs)),
        muted: status.muted,
      );
    }

    final phase = switch (status.reason) {
      .STOP_REASON_FOUND => OutgoingPhase.found,
      .STOP_REASON_STOPPED_REMOTELY => OutgoingPhase.stoppedElsewhere,
      .STOP_REASON_FAILED => OutgoingPhase.noSound,
      _ => OutgoingPhase.timedOut,
    };
    return ring.copyWith(phase: phase);
  }

  OutgoingRing _updateOutgoing(OutgoingRing ring) {
    _outgoing[ring.deviceId] = ring;
    _outgoingTimers.remove(ring.deviceId)?.cancel();

    if ((ring.phase, ring.endsAt) case (.ringing, final endsAt?)) {
      final after = endsAt.difference(_clock()) + _endGrace;
      _outgoingTimers[ring.deviceId] = Timer(
        after,
        () => _onOutgoingOverdue(ring.deviceId),
      );
    }

    _emit();
    return ring;
  }

  void _onOutgoingOverdue(String deviceId) {
    _outgoingTimers.remove(deviceId);
    final ring = _outgoing[deviceId];
    if (ring == null || ring.phase != .ringing) {
      return;
    }

    _updateOutgoing(ring.copyWith(phase: .timedOut));
  }

  Future<void> _fetchInfo(Session session) async {
    final deviceId = session.remoteDeviceId;
    try {
      final info = await session.call(
        featureId,
        GetRingInfo(),
        RingInfo.new,
        timeout: requestTimeout,
      );
      _remote[deviceId] = RemoteRingInfo.answered(info);
      if (_outgoing[deviceId] case final ring?
          when !ring.isActive && ring.phase.isProblem) {
        _outgoing.remove(deviceId);
      }
    } on Object catch (error) {
      if (session.isClosed) {
        return;
      }

      printWarning('Asking $deviceId about ringing failed', error);
      _remote[deviceId] = const RemoteRingInfo.failed();
    }

    _emit();
  }

  /// Sends this device's ring info to the others when it changed, such as
  /// after Do Not Disturb access was granted.
  void _onLocalInfoChanged() {
    _rememberDndAccess();
    final info = localInfo;
    final previous = _lastSentInfo;
    _lastSentInfo = info;
    if (previous != null && info != previous) {
      unawaited(host.broadcast(featureId, info));
    }

    _emit();
  }

  void _rememberDndAccess() {
    final abilities = _controller.abilities;
    final granted = abilities.needsDndAccess && abilities.dndAccessGranted;
    if (!granted || settings.hadDndAccess) {
      return;
    }

    unawaited(settings.setHadDndAccess(true));
  }

  String _nameOf(String deviceId, Session? session) =>
      session?.remoteDevice?.name ??
      host.trustStore[deviceId]?.name ??
      deviceId;

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
