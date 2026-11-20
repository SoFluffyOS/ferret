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

/// The phone's side of "use this phone's camera": a computer asks, the
/// owner answers Once, Always or No in Ferret (a computer told Always
/// isn't asked again), and the camera and microphone go to one computer
/// until either side stops. The camera never stays on for a computer that
/// dropped off. Each time ends with an audit line.
class CameraSource {
  CameraSource({
    required FeatureHost host,
    required String featureId,
    required CameraCapture capture,
    required MirroringSettings settings,
    required CameraTexts Function(String deviceName, {bool withSound}) texts,
    bool Function()? isBusy,
    DateTime Function()? clock,
    this.askTimeout = const Duration(seconds: 60),
    this.denyCooldown = const Duration(seconds: 30),
  }) : _host = host,
       _featureId = featureId,
       _capture = capture,
       _settings = settings,
       _texts = texts,
       _isBusy = isBusy ?? _never,
       _clock = clock ?? DateTime.now;

  /// How long the owner has to answer before the request is denied.
  final Duration askTimeout;

  /// After a no, the same computer is turned away this long, so it can't
  /// flood the owner with questions.
  final Duration denyCooldown;

  final FeatureHost _host;
  final String _featureId;
  final CameraCapture _capture;
  final MirroringSettings _settings;
  final CameraTexts Function(String deviceName, {bool withSound}) _texts;

  /// Whether this phone already shows its screen, or is asked to.
  final bool Function() _isBusy;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final Map<String, DateTime> _deniedUntil = {};

  /// What the camera said before the computer heard its yes.
  final List<CaptureEvent> _early = [];

  StreamSubscription<CaptureEvent>? _events;
  CameraSupport _support = const .none();
  ShareRequest? _pending;
  StartRequest? _pendingRequest;
  Timer? _askTimer;
  ActiveCamera? _active;
  MirrorRecord? _lastRecord;
  FrameSender? _sender;
  BitrateController? _bitrate;
  bool _sendsSound = false;
  int _configId = 0;
  int _soundSequence = 0;
  int _pendingSound = 0;

  /// Sound on its way at which more is dropped: half a second of it.
  static const _maxPendingSound = 25;

  /// What this phone's cameras can do, as last checked.
  CameraSupport get support => _support;

  /// A computer waiting for the owner's answer.
  ShareRequest? get pending => _pending;

  /// The computer that uses the camera right now.
  ActiveCamera? get active => switch (_sender) {
    null => null,
    _ => _active,
  };

  /// A computer is being asked about, or has the camera, or is about to.
  bool get isBusy => _active != null || _pending != null;

  /// The most recent time the camera was used since the app started,
  /// until dismissed.
  MirrorRecord? get lastRecord => _lastRecord;

  bool get enabled => _settings.cameraEnabled;

  /// The computers that turn the camera on without asking.
  List<String> get alwaysAllowed => _settings.cameraAlways;

  Stream<void> get changes => _changes.stream;

  Future<void> start() async {
    await _checkSupport();
    _events = _capture.events.listen(_onCaptureEvent);
  }

  /// Answers a computer asking for the camera: no with a reason, or
  /// "asking the owner" with the answer sent later. A computer the owner
  /// told Always gets the same answer, and its yes right after.
  Future<GeneratedMessage> onRequest(
    Session session,
    StartRequest request,
  ) async {
    final deviceId = session.remoteDeviceId;
    if (request.version > MirrorProtocol.version) {
      return StartDeny(reason: .DENY_REASON_VERSION);
    }

    if (!_settings.cameraEnabled || _settings.isCameraBlocked(deviceId)) {
      return StartDeny(reason: .DENY_REASON_TURNED_OFF);
    }

    final support = await _checkSupport();
    if (!support.canCapture) {
      return StartDeny(reason: .DENY_REASON_UNSUPPORTED);
    }

    if (!request.codecs.contains(Codec.CODEC_H264)) {
      return StartDeny(reason: .DENY_REASON_NO_CODEC);
    }

    final pending = _pending;
    if (pending != null && pending.deviceId == deviceId) {
      return StartPending(timeoutSeconds: _secondsLeft(pending));
    }

    if (_active != null || pending != null || _isBusy()) {
      return StartDeny(reason: .DENY_REASON_BUSY);
    }

    final deniedUntil = _deniedUntil[deviceId];
    if (deniedUntil != null && _clock().isBefore(deniedUntil)) {
      return StartDeny(reason: .DENY_REASON_DENIED);
    }

    final asked = ShareRequest(
      deviceId: deviceId,
      deviceName: _host.displayNameOf(deviceId),
      askedAt: _clock(),
    );
    if (_settings.cameraAlways.contains(deviceId)) {
      unawaited(_turnOnAfterReply(asked, request));
      return StartPending();
    }

    _pending = asked;
    _pendingRequest = request;
    _askTimer = Timer(askTimeout, () => unawaited(_timedOut(asked)));
    _emit();
    return StartPending(timeoutSeconds: askTimeout.inSeconds);
  }

  /// The owner answered the question in [pending].
  Future<void> answer(ControlChoice choice) async {
    final pending = _pending;
    final request = _pendingRequest;
    if (pending == null || request == null) {
      return;
    }

    _dropAsk();
    final deviceId = pending.deviceId;
    if (choice == .no) {
      _deniedUntil[deviceId] = _clock().add(denyCooldown);
      _emit();
      await _send(deviceId, StartDeny(reason: .DENY_REASON_DENIED));
      return;
    }

    if (choice == .always) {
      await _settings.setCameraAlways(deviceId, true);
    }

    _deniedUntil.remove(deviceId);
    _emit();
    await _turnOn(pending, request);
  }

  /// The computer is done, or gave up waiting for the answer.
  Future<void> onStop(Session session) async {
    final deviceId = session.remoteDeviceId;
    if (_pending?.deviceId == deviceId) {
      _dropAsk();
      _emit();
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

  /// The computer picks another camera.
  Future<void> onSwitch(Session session, CameraSwitch change) async {
    final active = _active;
    final wanted = MirrorProtocol.lensFromProto(change.lens);
    if (active == null ||
        active.deviceId != session.remoteDeviceId ||
        wanted == null) {
      return;
    }

    MirrorLens? lens;
    try {
      lens = await _capture.setLens(wanted);
    } on Object catch (error) {
      printWarning('Switching the camera failed', error);
    }

    if (!identical(_active, active)) {
      return;
    }

    final switched = active.copyWith(lens: lens);
    _active = switched;
    _emit();
    await _sendState(switched);
  }

  /// The computer's numbers for the last second: answered with this
  /// side's, and used to pick the bitrate.
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
    if (changed != null) {
      await _capture.setBitrate(changed);
    }

    await _send(
      session.remoteDeviceId,
      Stats(
        sentAtMs: Int64(_clock().millisecondsSinceEpoch),
        echoSentAtMs: stats.sentAtMs,
        fps: counts.sent,
        droppedFrames: counts.dropped,
        bitrateKbps: bitrate.bitrate ~/ 1000,
      ),
    );
  }

  /// A camera is never left on for a computer that is gone: coming back
  /// means asking again, or Always.
  Future<void> onSessionClosed(String deviceId) async {
    if (_pending?.deviceId == deviceId) {
      _dropAsk();
      _emit();
    }

    if (_active?.deviceId == deviceId) {
      await _end(.lostConnection);
    }
  }

  /// Stop on this phone: the computer's picture goes away at once.
  Future<void> stop() async {
    if (_active == null) {
      return;
    }

    await _end(.stoppedOnPhone, notify: .STOP_REASON_STOPPED_ON_SOURCE);
  }

  /// Lets computers ask for the camera, or not; off ends any use and
  /// request.
  Future<void> setEnabled(bool enabled) async {
    await _settings.setCameraEnabled(enabled);
    if (!enabled) {
      await _turnAway(null);
    }

    _emit();
  }

  /// Whether [deviceId] may ask for the camera. Turning it away also ends
  /// its request, and its use of the camera, right now.
  Future<void> setBlocked(String deviceId, bool blocked) async {
    await _settings.setCameraBlocked(deviceId, blocked);
    if (blocked) {
      await _turnAway(deviceId);
    }

    _emit();
  }

  /// Every computer asks again next time.
  Future<void> forgetAlways() async {
    await _settings.clearCameraAlways();
    _emit();
  }

  void dismissRecord() {
    _lastRecord = null;
    _emit();
  }

  Future<void> dispose() async {
    _dropAsk();
    if (_active != null) {
      await _end(.lostConnection, notify: .STOP_REASON_STOPPED_ON_SOURCE);
    }

    await _events?.cancel();
    await _capture.dispose();
    await _changes.close();
  }

  static bool _never() => false;

  Future<CameraSupport> _checkSupport() async {
    try {
      _support = await _capture.support();
    } on Object catch (error) {
      printWarning('Could not check the cameras', error);
      _support = const .none();
    }

    return _support;
  }

  /// Ends what [deviceId] has going, or what anyone has with null.
  Future<void> _turnAway(String? deviceId) async {
    final pending = _pending;
    if (pending != null && (deviceId == null || pending.deviceId == deviceId)) {
      _dropAsk();
      await _send(
        pending.deviceId,
        StartDeny(reason: .DENY_REASON_TURNED_OFF),
      );
    }

    final active = _active;
    if (active != null && (deviceId == null || active.deviceId == deviceId)) {
      await _end(.turnedOff, notify: .STOP_REASON_TURNED_OFF);
    }

    _emit();
  }

  /// For a computer told Always: its answer to the request leaves first.
  Future<void> _turnOnAfterReply(
    ShareRequest asked,
    StartRequest request,
  ) async {
    await Future<void>.delayed(Duration.zero);
    if (isBusy || _isBusy()) {
      await _send(asked.deviceId, StartDeny(reason: .DENY_REASON_BUSY));
      return;
    }

    await _turnOn(asked, request);
  }

  /// The owner said yes: Android's own permission first when it is
  /// missing, then the camera. A microphone the owner keeps closed only
  /// leaves the sound out.
  Future<void> _turnOn(ShareRequest asked, StartRequest request) async {
    final deviceId = asked.deviceId;
    final soundCodec = MirrorProtocol.pickAudio(request.audioCodecs);
    final wantsSound = soundCodec != null;
    final starting = ActiveCamera(
      deviceId: deviceId,
      deviceName: asked.deviceName,
      startedAt: _clock(),
      lens: MirrorProtocol.lensFromProto(request.camera.lens) ?? .back,
    );
    _active = starting;
    _emit();

    final support = await _access(withMicrophone: wantsSound);
    if (!identical(_active, starting)) {
      return;
    }

    if (!support.cameraGranted) {
      _active = null;
      _emit();
      await _send(deviceId, StartDeny(reason: .DENY_REASON_CANNOT_ASK));
      return;
    }

    final sentCodec = switch (support.microphoneGranted) {
      true => soundCodec,
      false => null,
    };
    final lens = await _startCapture(starting, request, audioCodec: sentCodec);
    if (!identical(_active, starting)) {
      if (lens != null) {
        await _stopCapture();
      }

      return;
    }

    if (lens == null) {
      _active = null;
      _emit();
      await _send(deviceId, StartDeny(reason: .DENY_REASON_CANNOT_ASK));
      return;
    }

    final active = ActiveCamera(
      deviceId: deviceId,
      deviceName: asked.deviceName,
      startedAt: starting.startedAt,
      lens: lens,
      withSound: sentCodec != null,
    );
    _begin(active);
    await _send(
      deviceId,
      StartAccept(
        version: MirrorProtocol.version,
        codec: .CODEC_H264,
        audio: _soundAnswer(
          wantsSound: wantsSound,
          withSound: active.withSound,
        ),
        audioCodec: switch (sentCodec) {
          final codec? => MirrorProtocol.audioToProto(codec),
          null => null,
        },
      ),
    );
    await _sendState(active);
    for (final event in _early) {
      _onCaptureEvent(event);
    }

    _early.clear();
  }

  AudioAnswer _soundAnswer({
    required bool wantsSound,
    required bool withSound,
  }) {
    if (!wantsSound) {
      return .AUDIO_ANSWER_UNSPECIFIED;
    }

    if (!withSound) {
      return .AUDIO_ANSWER_OFF;
    }

    return .AUDIO_ANSWER_SENDING;
  }

  Future<CameraSupport> _access({required bool withMicrophone}) async {
    final missing =
        !_support.cameraGranted ||
        (withMicrophone && !_support.microphoneGranted);
    if (!missing) {
      return _support;
    }

    try {
      _support = await _capture.requestAccess(withMicrophone: withMicrophone);
    } on Object catch (error) {
      printWarning('Asking for the camera failed', error);
    }

    return _support;
  }

  Future<MirrorLens?> _startCapture(
    ActiveCamera starting,
    StartRequest request, {
    required MirrorAudioCodec? audioCodec,
  }) async {
    final wantedLong = switch (request.maxWidth > request.maxHeight) {
      true => request.maxWidth,
      false => request.maxHeight,
    };
    // A viewer asks for a square box, not knowing how the phone is held;
    // a webcam's picture is 16:9 inside it.
    final wantedShort = switch (request.maxWidth > request.maxHeight) {
      true => request.maxHeight,
      false => request.maxWidth,
    }.clamp(0, wantedLong * 9 ~/ 16);
    final fps = switch (request.maxFps) {
      0 => MirrorProtocol.cameraFps,
      final wanted => wanted.clamp(1, MirrorProtocol.cameraFps),
    };

    _early.clear();
    try {
      return await _capture.start(
        CameraCaptureOptions(
          lens: starting.lens,
          maxLongSide: switch (wantedLong) {
            0 => MirrorProtocol.cameraLongSide,
            _ => wantedLong.clamp(1, MirrorProtocol.maxLongSide),
          },
          maxShortSide: switch (wantedShort) {
            0 => MirrorProtocol.cameraShortSide,
            _ => wantedShort.clamp(1, MirrorProtocol.maxShortSide),
          },
          fps: fps,
          bitrate: MirrorProtocol.cameraStartBitrate,
          audioCodec: audioCodec,
        ),
        _texts(starting.deviceName, withSound: audioCodec != null),
      );
    } on Object catch (error) {
      printWarning('The camera did not start', error);
      return null;
    }
  }

  void _begin(ActiveCamera active) {
    final deviceId = active.deviceId;
    _active = active;
    _configId = 0;
    _soundSequence = 0;
    _pendingSound = 0;
    _sendsSound = false;
    _bitrate = BitrateController(
      min: MirrorProtocol.cameraMinBitrate,
      max: MirrorProtocol.cameraMaxBitrate,
      start: MirrorProtocol.cameraStartBitrate,
    );
    _sender = FrameSender(
      send: (frame) => _sendFrame(deviceId, frame),
      requestKeyframe: () => unawaited(_capture.requestKeyframe()),
    );
    _emit();
  }

  void _onCaptureEvent(CaptureEvent event) {
    final active = _active;
    if (active == null) {
      return;
    }

    if (_sender == null) {
      _early.add(event);
      return;
    }

    switch (event) {
      case CaptureFrame(:final frame):
        _sender?.offer(frame);
      case CaptureConfigured(:final config):
        _onConfig(active, config);
      case CaptureAudioConfigured(:final config):
        _onAudioConfig(active, config);
      case CaptureAudio(:final packet):
        _offerSound(active, packet);
      case CaptureAudioEnded():
        _sendsSound = false;
        unawaited(_send(active.deviceId, AudioEnded()));
      case CaptureEnded(:final end):
        unawaited(_onCaptureEnded(end));
      case CaptureScreenOff():
        return;
    }
  }

  void _onConfig(ActiveCamera active, MirrorStreamConfig config) {
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
          fps: config.fps,
          sps: config.sps,
          pps: config.pps,
          turn: config.turn,
        ),
      ),
    );
  }

  /// Only a camera whose owner let the microphone go along sends any.
  void _onAudioConfig(ActiveCamera active, MirrorAudioConfig config) {
    if (!active.withSound) {
      return;
    }

    _sendsSound = true;
    unawaited(
      _send(
        active.deviceId,
        AudioConfig(
          codec: MirrorProtocol.audioToProto(config.codec),
          sampleRate: config.sampleRate,
          channels: config.channels,
        ),
      ),
    );
  }

  /// Sends sound without letting it pile up: what the connection has no
  /// room for is dropped, and the computer hears a short gap.
  void _offerSound(ActiveCamera active, MirrorAudioPacket packet) {
    final sequence = _soundSequence++;
    final waits = _pendingSound >= _maxPendingSound;
    if (!active.withSound || !_sendsSound || waits) {
      return;
    }

    _pendingSound++;
    unawaited(
      _send(
        active.deviceId,
        AudioFrame(
          sequence: Int64(sequence),
          ptsUs: Int64(packet.ptsUs),
          data: packet.data,
        ),
      ).whenComplete(() => _pendingSound--),
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

  /// Ends the use: the camera closes first, then the audit line is
  /// written.
  Future<void> _end(MirrorEnd end, {StopReason? notify}) async {
    final active = _active;
    if (active == null) {
      return;
    }

    final wasOn = _sender != null;
    _active = null;
    _sender = null;
    _bitrate = null;
    _sendsSound = false;
    _early.clear();
    final record = MirrorRecord(
      deviceId: active.deviceId,
      deviceName: active.deviceName,
      role: .shared,
      startedAt: active.startedAt,
      endedAt: _clock(),
      end: end,
      camera: true,
    );
    if (wasOn) {
      _lastRecord = record;
    }

    _emit();
    await _stopCapture();
    if (wasOn) {
      await _settings.addRecord(record);
    }

    if (notify != null) {
      await _send(active.deviceId, Stop(reason: notify));
    }

    _emit();
  }

  Future<void> _stopCapture() async {
    try {
      await _capture.stop();
    } on Object catch (error) {
      printWarning('Closing the camera failed', error);
    }
  }

  Future<void> _sendState(ActiveCamera active) => _send(
    active.deviceId,
    CameraState(
      lens: MirrorProtocol.lensToProto(active.lens),
      lenses: _support.lenses.map(MirrorProtocol.lensToProto),
    ),
  );

  void _dropAsk() {
    _askTimer?.cancel();
    _askTimer = null;
    _pending = null;
    _pendingRequest = null;
  }

  Future<void> _timedOut(ShareRequest pending) async {
    if (!identical(_pending, pending)) {
      return;
    }

    _dropAsk();
    _emit();
    await _send(pending.deviceId, StartDeny(reason: .DENY_REASON_TIMEOUT));
  }

  int _secondsLeft(ShareRequest pending) {
    final left = askTimeout - _clock().difference(pending.askedAt);
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
      printWarning('Camera message to $deviceId failed', error);
    }
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
