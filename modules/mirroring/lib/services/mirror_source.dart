import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/bitrate_controller.dart';
import 'package:mirroring/services/frame_sender.dart';
import 'package:mirroring/services/mirror_protocol.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';

/// The phone's side of screen mirroring: a computer asks, the owner
/// answers the system's own prompt (every time), and the screen is sent to
/// one computer at a time until either side stops. Each time ends with an
/// audit line.
class MirrorSource {
  MirrorSource({
    required FeatureHost host,
    required String featureId,
    required ScreenCapture capture,
    required MirroringSettings settings,
    required ConsentTexts Function(String deviceName) texts,
    DateTime Function()? clock,
    this.consentTimeout = const Duration(seconds: 60),
    this.denyCooldown = const Duration(seconds: 30),
    this.reconnectGrace = const Duration(seconds: 20),
  }) : _host = host,
       _featureId = featureId,
       _capture = capture,
       _settings = settings,
       _texts = texts,
       _clock = clock ?? DateTime.now;

  /// How long the owner has to answer before the request is denied.
  final Duration consentTimeout;

  /// After a no, the same device is turned away this long, so it can't
  /// flood the owner with prompts.
  final Duration denyCooldown;

  /// How long the capture is kept after the computer's connection
  /// dropped, so the picture picks up again without a new prompt: it is
  /// still the capture the owner said yes to.
  final Duration reconnectGrace;

  final FeatureHost _host;
  final String _featureId;
  final ScreenCapture _capture;
  final MirroringSettings _settings;
  final ConsentTexts Function(String deviceName) _texts;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final Map<String, DateTime> _deniedUntil = {};

  StreamSubscription<CaptureEvent>? _events;
  CaptureSupport _support = const .none();
  ShareRequest? _pending;
  ActiveShare? _active;
  MirrorRecord? _lastRecord;
  FrameSender? _sender;
  BitrateController? _bitrate;
  MirrorStreamConfig? _lastConfig;
  Timer? _graceTimer;
  int _configId = 0;

  /// What this phone can capture with, as checked at start.
  CaptureSupport get support => _support;

  /// A computer waiting for the owner's answer.
  ShareRequest? get pending => _pending;

  /// The computer seeing this screen right now.
  ActiveShare? get active => _active;

  /// The most recent time this screen was shown since the app started,
  /// until dismissed.
  MirrorRecord? get lastRecord => _lastRecord;

  Stream<void> get changes => _changes.stream;

  Future<void> start() async {
    try {
      _support = await _capture.support();
    } on Object catch (error) {
      printWarning('Could not check screen capture support', error);
    }

    _events = _capture.events.listen(_onCaptureEvent);
  }

  /// Answers a computer asking to see the screen: no with a reason, or
  /// "asking the owner" with the answer sent later.
  Future<GeneratedMessage> onRequest(
    Session session,
    StartRequest request,
  ) async {
    final deviceId = session.remoteDeviceId;
    if (request.version > MirrorProtocol.version) {
      return StartDeny(reason: .DENY_REASON_VERSION);
    }

    if (!_settings.enabled || _settings.isBlocked(deviceId)) {
      return StartDeny(reason: .DENY_REASON_TURNED_OFF);
    }

    if (!_support.canCapture) {
      return StartDeny(reason: .DENY_REASON_UNSUPPORTED);
    }

    final active = _active;
    if (active != null && active.deviceId == deviceId && active.reconnecting) {
      unawaited(_resume(active));
      return StartPending();
    }

    if (active != null || _pending != null) {
      return _answerWhileBusy(deviceId);
    }

    final codec = MirrorProtocol.pick(request.codecs, _support.supports);
    if (codec == null) {
      return StartDeny(reason: .DENY_REASON_NO_CODEC);
    }

    final deniedUntil = _deniedUntil[deviceId];
    if (deniedUntil != null && _clock().isBefore(deniedUntil)) {
      return StartDeny(reason: .DENY_REASON_DENIED);
    }

    final pending = ShareRequest(
      deviceId: deviceId,
      deviceName: _host.displayNameOf(deviceId),
      askedAt: _clock(),
    );
    _pending = pending;
    _emit();
    unawaited(_ask(pending, codec, request));
    return StartPending(timeoutSeconds: consentTimeout.inSeconds);
  }

  /// The computer is done, or gave up waiting for the answer.
  Future<void> onStop(Session session) async {
    final deviceId = session.remoteDeviceId;
    if (_pending?.deviceId == deviceId) {
      await _dropPending();
      return;
    }

    if (_active?.deviceId == deviceId) {
      await _end(.viewerDone);
    }
  }

  Future<void> onKeyframeRequest(Session session) async {
    if (_active?.deviceId != session.remoteDeviceId) {
      return;
    }

    await _capture.requestKeyframe();
  }

  /// The computer's numbers for the last second: answered with this side's,
  /// and used to pick the bitrate.
  Future<void> onStats(Session session, Stats stats) async {
    final sender = _sender;
    final bitrate = _bitrate;
    if (_active?.deviceId != session.remoteDeviceId ||
        sender == null ||
        bitrate == null) {
      return;
    }

    final counts = sender.takeCounts();
    final congested =
        counts.dropped > 0 || stats.droppedFrames > 0 || sender.isBackedUp;
    final changed = bitrate.onWindow(congested: congested);
    if (changed != null && _active?.codec == .h264) {
      await _capture.setBitrate(changed);
    }

    await _send(
      session.remoteDeviceId,
      Stats(
        sentAtMs: Int64(_clock().millisecondsSinceEpoch),
        echoSentAtMs: stats.sentAtMs,
        fps: counts.sent,
        droppedFrames: counts.dropped,
        bitrateKbps: _bitrateKbps(bitrate),
      ),
    );
  }

  Future<void> onSessionClosed(String deviceId) async {
    if (_pending?.deviceId == deviceId) {
      await _dropPending();
    }

    final active = _active;
    if (active == null || active.deviceId != deviceId) {
      return;
    }

    _active = active.copyWith(reconnecting: true);
    _graceTimer?.cancel();
    _graceTimer = Timer(
      reconnectGrace,
      () => unawaited(_end(.lostConnection)),
    );
    _emit();
  }

  /// Stop on this phone: the computer's picture goes away at once.
  Future<void> stop() async {
    if (_active == null) {
      return;
    }

    await _end(.stoppedOnPhone, notify: .STOP_REASON_STOPPED_ON_SOURCE);
  }

  /// Turns screen mirroring on or off; off ends any sharing and request.
  Future<void> setEnabled(bool enabled) async {
    await _settings.setEnabled(enabled);
    if (enabled) {
      _emit();
      return;
    }

    if (_pending case final pending?) {
      await _dropPending();
      await _send(
        pending.deviceId,
        StartDeny(reason: .DENY_REASON_TURNED_OFF),
      );
    }

    if (_active != null) {
      await _end(.turnedOff, notify: .STOP_REASON_TURNED_OFF);
    }

    _emit();
  }

  /// Whether [deviceId] may ask to see this screen. Turning it away also
  /// ends its request, and its look at the screen, right now.
  Future<void> setBlocked(String deviceId, bool blocked) async {
    await _settings.setBlocked(deviceId, blocked);
    if (!blocked) {
      _emit();
      return;
    }

    if (_pending?.deviceId == deviceId) {
      await _dropPending();
      await _send(deviceId, StartDeny(reason: .DENY_REASON_TURNED_OFF));
    }

    if (_active?.deviceId == deviceId) {
      await _end(.turnedOff, notify: .STOP_REASON_TURNED_OFF);
    }

    _emit();
  }

  void dismissRecord() {
    _lastRecord = null;
    _emit();
  }

  Future<void> clearHistory() async {
    await _settings.clearHistory();
    _lastRecord = null;
    _emit();
  }

  Future<void> dispose() async {
    if (_pending != null) {
      await _dropPending();
    }

    if (_active != null) {
      await _end(.lostConnection, notify: .STOP_REASON_STOPPED_ON_SOURCE);
    }

    await _events?.cancel();
    await _capture.dispose();
    await _changes.close();
  }

  GeneratedMessage _answerWhileBusy(String deviceId) {
    final pending = _pending;
    if (pending != null && pending.deviceId == deviceId) {
      return StartPending(timeoutSeconds: _secondsLeft(pending));
    }

    return StartDeny(reason: .DENY_REASON_BUSY);
  }

  /// Shows the system prompt and, on a yes, starts sending the screen.
  Future<void> _ask(
    ShareRequest pending,
    MirrorCodec codec,
    StartRequest request,
  ) async {
    final result = await _requestConsent(pending);
    if (!identical(_pending, pending)) {
      if (result == .granted) {
        await _capture.stop();
      }

      return;
    }

    _pending = null;
    final deviceId = pending.deviceId;
    if (result != .granted) {
      if (result == .denied) {
        _deniedUntil[deviceId] = _clock().add(denyCooldown);
      }

      _emit();
      await _send(deviceId, StartDeny(reason: _denyReasonOf(result)));
      return;
    }

    _deniedUntil.remove(deviceId);
    final active = ActiveShare(
      deviceId: deviceId,
      deviceName: pending.deviceName,
      startedAt: _clock(),
      codec: codec,
    );
    _begin(active);
    await _send(
      deviceId,
      StartAccept(
        version: MirrorProtocol.version,
        codec: MirrorProtocol.toProto(codec),
      ),
    );

    final started = await _startCapture(codec, request);
    if (!started && identical(_active, active)) {
      await _end(.failed, notify: .STOP_REASON_FAILED);
    }
  }

  Future<ConsentResult> _requestConsent(ShareRequest pending) async {
    try {
      return await _capture.requestConsent(
        _texts(pending.deviceName),
        consentTimeout,
      );
    } on Object catch (error) {
      printWarning('Asking for screen capture failed', error);
      return .failed;
    }
  }

  void _begin(ActiveShare active) {
    final deviceId = active.deviceId;
    _active = active;
    _configId = 0;
    _bitrate = BitrateController();
    _sender = FrameSender(
      send: (frame) => _sendFrame(deviceId, frame),
      requestKeyframe: () => unawaited(_capture.requestKeyframe()),
      maxPendingFrames: switch (active.codec) {
        .h264 => 6,
        .jpeg => 2,
      },
    );
    _emit();
  }

  Future<bool> _startCapture(MirrorCodec codec, StartRequest request) async {
    final (mostLong, mostShort) = switch (codec) {
      .h264 => (MirrorProtocol.maxLongSide, MirrorProtocol.maxShortSide),
      .jpeg => (
        MirrorProtocol.jpegMaxLongSide,
        MirrorProtocol.jpegMaxShortSide,
      ),
    };
    final wantedLong = switch (request.maxWidth > request.maxHeight) {
      true => request.maxWidth,
      false => request.maxHeight,
    };
    final wantedShort = switch (request.maxWidth > request.maxHeight) {
      true => request.maxHeight,
      false => request.maxWidth,
    };

    try {
      return await _capture.start(
        CaptureOptions(
          codec: codec,
          maxLongSide: MirrorProtocol.sideFor(wantedLong, mostLong),
          maxShortSide: MirrorProtocol.sideFor(wantedShort, mostShort),
          fps: MirrorProtocol.fpsFor(codec, request.maxFps),
          bitrate: MirrorProtocol.startBitrate,
        ),
      );
    } on Object catch (error) {
      printWarning('Screen capture did not start', error);
      return false;
    }
  }

  void _onCaptureEvent(CaptureEvent event) {
    final active = _active;
    if (active == null) {
      return;
    }

    switch (event) {
      case CaptureFrame(:final frame):
        _sender?.offer(frame);
      case CaptureConfigured(:final config):
        _onConfig(active, config);
      case CaptureScreenOff(:final off):
        unawaited(_send(active.deviceId, SourceState(screenOff: off)));
      case CaptureEnded(:final end):
        unawaited(_onCaptureEnded(end));
    }
  }

  /// The computer is back while its capture still runs: pictures go on,
  /// starting from a fresh config and keyframe. No prompt: it is the same
  /// capture the owner said yes to.
  Future<void> _resume(ActiveShare active) async {
    _graceTimer?.cancel();
    _graceTimer = null;
    final resumed = active.copyWith(reconnecting: false);
    _active = resumed;
    _emit();

    // The answer to the request itself has to leave first.
    await Future<void>.delayed(Duration.zero);
    if (!identical(_active, resumed)) {
      return;
    }

    await _send(
      resumed.deviceId,
      StartAccept(
        version: MirrorProtocol.version,
        codec: MirrorProtocol.toProto(resumed.codec),
      ),
    );
    if (_lastConfig case final config?) {
      _onConfig(resumed, config);
    }

    await _capture.requestKeyframe();
  }

  void _onConfig(ActiveShare active, MirrorStreamConfig config) {
    _lastConfig = config;
    _configId++;
    _sender?.startConfig(_configId);
    unawaited(
      _send(
        active.deviceId,
        StreamConfig(
          configId: _configId,
          codec: MirrorProtocol.toProto(config.codec),
          width: config.width,
          height: config.height,
          rotation: config.rotation,
          fps: config.fps,
          sps: config.sps,
          pps: config.pps,
        ),
      ),
    );
  }

  Future<void> _onCaptureEnded(CaptureEnd end) => switch (end) {
    .stoppedByUser => _end(
      .stoppedOnPhone,
      notify: .STOP_REASON_STOPPED_ON_SOURCE,
    ),
    .endedBySystem => _end(.systemEnded, notify: .STOP_REASON_SYSTEM_ENDED),
    .failed => _end(.failed, notify: .STOP_REASON_FAILED),
  };

  /// Ends sharing: the capture stops first, then the audit line is written.
  Future<void> _end(MirrorEnd end, {StopReason? notify}) async {
    final active = _active;
    if (active == null) {
      return;
    }

    _graceTimer?.cancel();
    _graceTimer = null;
    _active = null;
    _sender = null;
    _bitrate = null;
    _lastConfig = null;
    final record = MirrorRecord(
      deviceId: active.deviceId,
      deviceName: active.deviceName,
      role: .shared,
      startedAt: active.startedAt,
      endedAt: _clock(),
      end: end,
    );
    _lastRecord = record;
    _emit();

    try {
      await _capture.stop();
    } on Object catch (error) {
      printWarning('Stopping the screen capture failed', error);
    }

    await _settings.addRecord(record);
    if (notify != null) {
      await _send(active.deviceId, Stop(reason: notify));
    }

    _emit();
  }

  Future<void> _dropPending() async {
    _pending = null;
    _emit();
    try {
      await _capture.cancelConsent();
    } on Object catch (error) {
      printWarning('Taking back the screen capture prompt failed', error);
    }
  }

  DenyReason _denyReasonOf(ConsentResult result) => switch (result) {
    .denied => .DENY_REASON_DENIED,
    .timedOut => .DENY_REASON_TIMEOUT,
    .cannotAsk => .DENY_REASON_CANNOT_ASK,
    .failed || .granted => .DENY_REASON_FAILED,
  };

  int _bitrateKbps(BitrateController bitrate) {
    if (_active?.codec != .h264) {
      return 0;
    }

    return bitrate.bitrate ~/ 1000;
  }

  int _secondsLeft(ShareRequest pending) {
    final left = consentTimeout - _clock().difference(pending.askedAt);
    if (left.isNegative) {
      return 0;
    }

    return left.inSeconds;
  }

  Future<void> _sendFrame(String deviceId, Frame frame) async {
    final session = _host.sessionFor(deviceId);
    if (session == null) {
      throw const SessionClosedException();
    }

    await session.send(_featureId, frame);
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

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
