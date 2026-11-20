import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart' as remote;
import 'package:fixnum/fixnum.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/bitrate_controller.dart';
import 'package:mirroring/services/frame_sender.dart';
import 'package:mirroring/services/mirror_protocol.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';
import 'package:protocol/protocol.dart';
import 'package:protocol/remote_input.dart' as wire;

/// The computer's side of "use another device as a display": it offers,
/// the other device's owner answers there, and on a yes this computer
/// makes a display the size of that device's screen, sends what is on it,
/// and takes that device's pointer and keys. One device at a time. The
/// display goes away when either side stops, the connection drops, or
/// the app quits.
class DisplaySource {
  DisplaySource({
    required FeatureHost host,
    required String featureId,
    required DisplayCapture capture,
    remote.InputInjector? injector,
    DateTime Function()? clock,
    this.offerTimeout = const Duration(seconds: 10),
    this.answerMargin = const Duration(seconds: 5),
  }) : _host = host,
       _featureId = featureId,
       _capture = capture,
       _injector = injector ?? remote.InputInjector.current(),
       _clock = clock ?? DateTime.now;

  /// How long the other device has to answer the offer itself.
  final Duration offerTimeout;

  /// Added to the other device's own time to ask before giving up on it.
  final Duration answerMargin;

  static const _maxEventsPerBatch = 512;
  static const _maxTextLength = 4096;

  final FeatureHost _host;
  final String _featureId;
  final DisplayCapture _capture;
  final remote.InputInjector _injector;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();

  StreamSubscription<CaptureEvent>? _events;
  DisplaySupport _support = const .none();
  ExtendSession? _current;
  ExtendRecord? _lastRecord;
  FrameSender? _sender;
  BitrateController? _bitrate;
  Timer? _answerTimer;
  int _configId = 0;
  bool _inputAllowed = false;

  /// What this computer can do as a display's source, as last checked.
  DisplaySupport get support => _support;

  /// The device being asked, or showing this computer's extra display.
  ExtendSession? get current => _current;

  /// How the last time ended, until dismissed.
  ExtendRecord? get lastRecord => _lastRecord;

  Stream<void> get changes => _changes.stream;

  /// Whether [session]'s device can be this computer's display.
  bool canExtendTo(Session session) =>
      session
          .remoteFeature(_featureId)
          ?.flags
          .contains(MirrorProtocol.displayFlag) ??
      false;

  /// Follows the capture. What this computer can do is checked when an
  /// offer is made, not before.
  Future<void> start() async {
    _events = _capture.events.listen(_onCaptureEvent);
  }

  /// Offers this computer's extra display to [deviceId]. Screen Recording
  /// is asked for first, in context, when it isn't allowed yet. Anything
  /// lent or offered to another device ends first.
  Future<void> offer(String deviceId) async {
    final current = _current;
    if (current?.deviceId == deviceId) {
      return;
    }

    if (current != null) {
      await stop();
    }

    final deviceName = _host.displayNameOf(deviceId);
    final support = await _checkSupport();
    if (!support.canExtend) {
      _record(deviceId, deviceName, .cannotExtend);
      return;
    }

    if (!support.screenRecordingGranted && !await _askScreenRecording()) {
      _record(deviceId, deviceName, .needsScreenRecording);
      return;
    }

    if (!support.inputGranted) {
      await _askInput();
    }

    final session = _host.sessionFor(deviceId);
    if (session == null) {
      _record(deviceId, deviceName, .notConnected);
      return;
    }

    if (!canExtendTo(session)) {
      _record(deviceId, deviceName, .unsupported);
      return;
    }

    final asking = ExtendSession(
      deviceId: deviceId,
      deviceName: deviceName,
      phase: .asking,
      askedAt: _clock(),
    );
    _current = asking;
    _lastRecord = null;
    _emit();

    final Envelope reply;
    try {
      reply = await session.request(
        _featureId,
        DisplayOffer(version: MirrorProtocol.version),
        timeout: offerTimeout,
      );
    } on SessionClosedException {
      _endAsking(asking, .lostConnection);
      return;
    } on Object catch (error) {
      printWarning('Offering a display to $deviceId failed', error);
      _endAsking(asking, .noAnswer);
      return;
    }

    if (!identical(_current, asking)) {
      return;
    }

    if (payloadOf(reply, StartPending.new) case final pending?) {
      final wait = Duration(seconds: pending.timeoutSeconds) + answerMargin;
      _current = asking.copyWith(answerBy: _clock().add(wait));
      _answerTimer = Timer(wait, () => _endAsking(_current, .timedOut));
      _emit();
      return;
    }

    if (payloadOf(reply, StartDeny.new) case final deny?) {
      _endAsking(asking, _endOfDeny(deny.reason));
      return;
    }

    _endAsking(asking, .noAnswer);
  }

  /// Stop on this computer: takes the display away, or the offer back.
  Future<void> stop() async {
    final current = _current;
    if (current == null) {
      return;
    }

    if (current.phase == .asking) {
      _endAsking(current, .stoppedHere);
      await _send(
        current.deviceId,
        Stop(reason: .STOP_REASON_STOPPED_ON_SOURCE),
      );
      return;
    }

    await _end(.stoppedHere, notify: .STOP_REASON_STOPPED_ON_SOURCE);
  }

  /// Opens the system page where Screen Recording is allowed.
  Future<void> openScreenRecordingSettings() =>
      _capture.openScreenRecordingSettings();

  /// The other device's owner said yes: its request for the display it
  /// was offered. A device that wasn't offered one is turned away.
  Future<GeneratedMessage> onRequest(
    Session session,
    StartRequest request,
  ) async {
    final deviceId = session.remoteDeviceId;
    final current = _current;
    if (request.version > MirrorProtocol.version) {
      return StartDeny(reason: .DENY_REASON_VERSION);
    }

    if (current == null ||
        current.deviceId != deviceId ||
        current.phase != .asking) {
      return StartDeny(reason: .DENY_REASON_DENIED);
    }

    if (!request.codecs.contains(Codec.CODEC_H264)) {
      _endAsking(current, .unsupported);
      return StartDeny(reason: .DENY_REASON_NO_CODEC);
    }

    final panel = request.display;
    if (panel.width == 0 || panel.height == 0) {
      _endAsking(current, .unsupported);
      return StartDeny(reason: .DENY_REASON_UNSUPPORTED);
    }

    _answerTimer?.cancel();
    final starting = current.copyWith(phase: .starting);
    _current = starting;
    _emit();
    unawaited(_turnOnAfterReply(starting, panel));
    return StartPending();
  }

  /// The other device's owner said no, or didn't answer.
  void onDecline(Session session, DisplayDecline decline) {
    final current = _current;
    if (current == null ||
        current.deviceId != session.remoteDeviceId ||
        current.phase != .asking) {
      return;
    }

    _endAsking(current, switch (decline.reason) {
      .DENY_REASON_TIMEOUT => .timedOut,
      _ => .declined,
    });
  }

  /// The other device is done with the display.
  Future<void> onStop(Session session) async {
    final current = _current;
    if (current == null || current.deviceId != session.remoteDeviceId) {
      return;
    }

    if (current.phase == .asking) {
      _endAsking(current, .declined);
      return;
    }

    await _end(.stoppedThere);
  }

  Future<void> onKeyframeRequest(Session session) async {
    if (!_isShowingOn(session.remoteDeviceId)) {
      return;
    }

    await _capture.requestKeyframe();
  }

  /// The other device's numbers for the last second: answered with this
  /// side's, and used to pick the bitrate.
  Future<void> onStats(Session session, Stats stats) async {
    final sender = _sender;
    final bitrate = _bitrate;
    if (!_isShowingOn(session.remoteDeviceId) ||
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

  /// The pointer, keys and text from the device showing the display. The
  /// pointer lands on the display; keys go to whatever has focus.
  Future<void> onInput(String deviceId, ControlInput input) async {
    if (!_isShowingOn(deviceId) || !_inputAllowed) {
      return;
    }

    final keys = <remote.InputAction>[];
    for (final event in input.events.take(_maxEventsPerBatch)) {
      switch (event.whichKind()) {
        case .pointer:
          if (keys.isNotEmpty) {
            await _inject(List.of(keys));
            keys.clear();
          }

          if (_pointerOf(event.pointer) case final pointer?) {
            await _guard(() => _capture.pointer(pointer));
          }
        case .key:
          if (_keyOf(event.key) case final key?) {
            keys.add(key);
          }
        case .text:
          final text = event.text.text;
          if (text.isNotEmpty) {
            keys.add(
              remote.TextAction(switch (text.length > _maxTextLength) {
                true => text.substring(0, _maxTextLength),
                false => text,
              }),
            );
          }
        case .button || .notSet:
          continue;
      }
    }

    if (keys.isNotEmpty) {
      await _inject(keys);
    }
  }

  /// A display is never left for a device that is gone.
  Future<void> onSessionClosed(String deviceId) async {
    final current = _current;
    if (current == null || current.deviceId != deviceId) {
      return;
    }

    if (current.phase == .asking) {
      _endAsking(current, .lostConnection);
      return;
    }

    await _end(.lostConnection);
  }

  void dismissRecord() {
    _lastRecord = null;
    _emit();
  }

  Future<void> dispose() async {
    _answerTimer?.cancel();
    if (_current != null) {
      await stop();
    }

    await _events?.cancel();
    await _capture.dispose();
    await _changes.close();
  }

  bool _isShowingOn(String deviceId) {
    final current = _current;
    return current != null &&
        current.deviceId == deviceId &&
        current.phase == .extending;
  }

  Future<DisplaySupport> _checkSupport() async {
    try {
      _support = await _capture.support();
    } on Object catch (error) {
      printWarning('Could not check the extra display', error);
      _support = const .none();
    }

    return _support;
  }

  Future<bool> _askScreenRecording() async {
    try {
      return await _capture.requestScreenRecording();
    } on Object catch (error) {
      printWarning('Asking for Screen Recording failed', error);
      return false;
    }
  }

  Future<bool> _askInput() async {
    try {
      return await _capture.requestInput();
    } on Object catch (error) {
      printWarning('Asking for Accessibility failed', error);
      return false;
    }
  }

  /// The yes leaves first, then the display is made.
  Future<void> _turnOnAfterReply(
    ExtendSession starting,
    DisplayPanel panel,
  ) async {
    await Future<void>.delayed(Duration.zero);
    if (!identical(_current, starting)) {
      return;
    }

    final started = await _startCapture(starting, panel);
    if (!identical(_current, starting)) {
      if (started) {
        await _stopCapture();
      }

      return;
    }

    if (!started) {
      _current = null;
      _record(starting.deviceId, starting.deviceName, .failed);
      await _send(starting.deviceId, StartDeny(reason: .DENY_REASON_FAILED));
      return;
    }

    final support = await _checkSupport();
    _inputAllowed = support.inputGranted;
    _begin(starting.copyWith(phase: .extending, startedAt: _clock()));
    await _send(
      starting.deviceId,
      StartAccept(version: MirrorProtocol.version, codec: .CODEC_H264),
    );
    await _send(
      starting.deviceId,
      ControlState(
        status: switch (_inputAllowed) {
          true => .CONTROL_STATUS_ALLOWED,
          false => .CONTROL_STATUS_NEEDS_SETUP,
        },
        kinds: const [
          .CONTROL_KIND_POINTER,
          .CONTROL_KIND_KEYS,
          .CONTROL_KIND_TEXT,
          .CONTROL_KIND_MOUSE,
        ],
      ),
    );
    await _capture.requestKeyframe();
  }

  Future<bool> _startCapture(ExtendSession starting, DisplayPanel panel) async {
    try {
      return await _capture.start(
        DisplayCaptureOptions(
          name: starting.deviceName,
          serial: serialOf(starting.deviceId),
          width: panel.width,
          height: panel.height,
          scale: switch (panel.scale) {
            >= 2 => 2,
            _ => 1,
          },
          refreshHz: switch (panel.refreshHz) {
            0 => 60,
            final hz => hz,
          },
          bitrate: MirrorProtocol.displayStartBitrate,
        ),
      );
    } on Object catch (error) {
      printWarning('The extra display did not start', error);
      return false;
    }
  }

  /// The same number for the same device every time, so macOS keeps
  /// where its owner put that device's display.
  static int serialOf(String deviceId) {
    var hash = 0x811c9dc5;
    for (final unit in deviceId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }

    return switch (hash) {
      0 => 1,
      _ => hash,
    };
  }

  void _begin(ExtendSession extending) {
    final deviceId = extending.deviceId;
    _current = extending;
    _configId = 0;
    _bitrate = BitrateController(
      min: MirrorProtocol.displayMinBitrate,
      max: MirrorProtocol.displayMaxBitrate,
      start: MirrorProtocol.displayStartBitrate,
    );
    _sender = FrameSender(
      send: (frame) => _sendFrame(deviceId, frame),
      requestKeyframe: () => unawaited(_capture.requestKeyframe()),
      maxPendingBytes: 4 * 1024 * 1024,
    );
    _emit();
  }

  void _onCaptureEvent(CaptureEvent event) {
    final current = _current;
    if (current == null || current.phase != .extending) {
      return;
    }

    switch (event) {
      case CaptureFrame(:final frame):
        _sender?.offer(frame);
      case CaptureConfigured(:final config):
        _onConfig(current, config);
      case CaptureEnded(:final end):
        unawaited(_onCaptureEnded(end));
      case CaptureAudioConfigured() ||
          CaptureAudio() ||
          CaptureAudioEnded() ||
          CaptureScreenOff():
        return;
    }
  }

  void _onConfig(ExtendSession current, MirrorStreamConfig config) {
    _configId++;
    _sender?.startConfig(_configId);
    unawaited(
      _send(
        current.deviceId,
        StreamConfig(
          configId: _configId,
          codec: MirrorProtocol.toProto(config.codec),
          width: config.width,
          height: config.height,
          fps: config.fps,
          sps: config.sps,
          pps: config.pps,
        ),
      ),
    );
  }

  Future<void> _onCaptureEnded(CaptureEnd end) => switch (end) {
    .stoppedByUser => _end(
      .stoppedHere,
      notify: .STOP_REASON_STOPPED_ON_SOURCE,
    ),
    .endedBySystem => _end(.systemEnded, notify: .STOP_REASON_SYSTEM_ENDED),
    .failed => _end(.failed, notify: .STOP_REASON_FAILED),
  };

  /// Ends the display: it goes away first, then the other device hears.
  Future<void> _end(ExtendEnd end, {StopReason? notify}) async {
    final current = _current;
    if (current == null) {
      return;
    }

    _current = null;
    _sender = null;
    _bitrate = null;
    _inputAllowed = false;
    _record(
      current.deviceId,
      current.deviceName,
      end,
      startedAt: current.startedAt,
    );
    await _stopCapture();
    await _inject(const [remote.ModifiersAction({})]);
    if (notify != null) {
      await _send(current.deviceId, Stop(reason: notify));
    }
  }

  void _endAsking(ExtendSession? asking, ExtendEnd end) {
    if (asking == null || !identical(_current, asking)) {
      return;
    }

    _answerTimer?.cancel();
    _answerTimer = null;
    _current = null;
    _record(asking.deviceId, asking.deviceName, end);
  }

  void _record(
    String deviceId,
    String deviceName,
    ExtendEnd end, {
    DateTime? startedAt,
  }) {
    _lastRecord = ExtendRecord(
      deviceId: deviceId,
      deviceName: deviceName,
      end: end,
      at: _clock(),
      startedAt: startedAt,
    );
    _emit();
  }

  ExtendEnd _endOfDeny(DenyReason reason) => switch (reason) {
    .DENY_REASON_DENIED => .declined,
    .DENY_REASON_TIMEOUT => .timedOut,
    .DENY_REASON_BUSY => .busy,
    .DENY_REASON_TURNED_OFF => .declined,
    .DENY_REASON_FAILED => .failed,
    _ => .unsupported,
  };

  MirrorPointer? _pointerOf(PointerInput input) {
    final phase = switch (input.phase) {
      .TOUCH_PHASE_DOWN => PointerPhase.down,
      .TOUCH_PHASE_MOVE => PointerPhase.move,
      .TOUCH_PHASE_UP || .TOUCH_PHASE_CANCEL => PointerPhase.up,
      .TOUCH_PHASE_HOVER => PointerPhase.hover,
      .TOUCH_PHASE_SCROLL => PointerPhase.scroll,
      _ => null,
    };
    if (phase == null) {
      return null;
    }

    return MirrorPointer(
      phase: phase,
      x: input.x.clamp(0.0, 1.0),
      y: input.y.clamp(0.0, 1.0),
      buttons: switch (input.button) {
        .MOUSE_BUTTON_RIGHT => 2,
        .MOUSE_BUTTON_MIDDLE => 4,
        _ => 1,
      },
      scrollX: input.scrollX * MirrorProtocol.pointsPerNotch,
      scrollY: input.scrollY * MirrorProtocol.pointsPerNotch,
    );
  }

  static final Map<wire.Key, remote.InputKey> _keys = {
    for (final key in remote.InputKey.values) ?_wireKey(key): key,
  };

  static remote.KeyAction? _keyOf(wire.KeyEvent event) {
    final key = _keys[event.key];
    if (key == null) {
      return null;
    }

    return remote.KeyAction(
      key,
      pressed: event.pressed,
      modifiers: {
        for (final modifier in event.modifiers)
          ?switch (modifier) {
            .MODIFIER_SHIFT => remote.KeyModifier.shift,
            .MODIFIER_CONTROL => remote.KeyModifier.control,
            .MODIFIER_ALT => remote.KeyModifier.alt,
            .MODIFIER_META => remote.KeyModifier.meta,
            _ => null,
          },
      },
    );
  }

  /// `KEY_ARROW_LEFT` is [remote.InputKey.arrowLeft], by name.
  static wire.Key? _wireKey(remote.InputKey key) {
    final name = switch (key.name) {
      final digit when digit.startsWith('digit') =>
        'KEY_DIGIT_${digit.substring(5)}',
      final camel =>
        'KEY_${camel.replaceAllMapped(RegExp('[A-Z]'), (match) => '_${match[0]}').toUpperCase()}',
    };
    for (final known in wire.Key.values) {
      if (known.name == name) {
        return known;
      }
    }

    return null;
  }

  Future<void> _inject(List<remote.InputAction> actions) =>
      _guard(() => _injector.inject(actions));

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      printWarning('Input on the extra display failed', error);
    }
  }

  Future<void> _stopCapture() async {
    try {
      await _capture.stop();
    } on Object catch (error) {
      printWarning('Taking the extra display away failed', error);
    }
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
      printWarning('Display message to $deviceId failed', error);
    }
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
