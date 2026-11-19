import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/phone_inputs.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';

/// The phone's side of control: a computer that sees this screen asks to
/// tap and type here, the owner answers Always, Once or No, and while it
/// lasts the phone says who controls it, with Stop. Control never outlives
/// the picture.
class SourceControl {
  SourceControl({
    required PhoneControl phone,
    required MirroringSettings settings,
    required Future<void> Function(String deviceId, GeneratedMessage message)
    send,
    DateTime Function()? clock,
    this.askTimeout = const Duration(seconds: 60),
  }) : _phone = phone,
       _settings = settings,
       _send = send,
       _clock = clock ?? DateTime.now;

  /// The most events one batch from a computer can carry out.
  static const maxEventsPerBatch = 512;

  /// How long the owner has to answer.
  final Duration askTimeout;

  final PhoneControl _phone;
  final MirroringSettings _settings;
  final Future<void> Function(String deviceId, GeneratedMessage message) _send;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();

  StreamSubscription<void>? _pathChanges;
  ControlRequest? _shownTo;
  ControlRequest? _pending;
  ControlRequest? _controller;
  Timer? _askTimer;
  Future<void> _inputs = Future.value();

  Stream<void> get changes => _changes.stream;

  /// Whether a computer can ever control this phone. An iPhone can't.
  bool get isSupported => _phone.isSupported;

  /// What would carry a computer's taps right now.
  ControlPath get path => _phone.path;

  /// A computer waiting for the owner's answer.
  ControlRequest? get pending => _pending;

  /// The computer that controls this phone right now.
  ControlRequest? get controller => _controller;

  /// The computers that control this phone without asking.
  List<String> get alwaysAllowed => _settings.controlAlways;

  Future<void> start() async {
    await _phone.start();
    _pathChanges = _phone.changes.listen((_) => unawaited(_onPathChanged()));
  }

  /// Opens Android's Accessibility settings on Ferret control.
  Future<bool> openServiceSettings() => _phone.openServiceSettings();

  /// Every computer asks again next time.
  Future<void> forgetAlways() async {
    await _settings.clearControlAlways();
    _emit();
  }

  /// This screen is now shown to [deviceId]: it hears where control
  /// stands.
  Future<void> onShown(String deviceId, String deviceName) async {
    _shownTo = ControlRequest(
      deviceId: deviceId,
      deviceName: deviceName,
      askedAt: _clock(),
    );
    await _sendState(deviceId);
  }

  /// The screen isn't shown any more, so control ends too.
  Future<void> onShareEnded() async {
    _shownTo = null;
    _dropAsk();
    await _endControl();
    _emit();
  }

  /// The computer that sees this screen asks to control it.
  Future<void> onAsk(String deviceId) async {
    final shown = _shownTo;
    if (shown == null || shown.deviceId != deviceId) {
      return;
    }

    final alreadyAnswered =
        _controller?.deviceId == deviceId || _pending?.deviceId == deviceId;
    if (alreadyAnswered || path == .none) {
      await _sendState(deviceId);
      return;
    }

    if (_settings.controlAlways.contains(deviceId)) {
      await _allow(shown);
      return;
    }

    final pending = ControlRequest(
      deviceId: deviceId,
      deviceName: shown.deviceName,
      askedAt: _clock(),
    );
    _pending = pending;
    _askTimer = Timer(askTimeout, () => unawaited(_timedOut(pending)));
    _emit();
    await _sendState(deviceId);
  }

  /// The owner answered the question in [pending].
  Future<void> answer(ControlChoice choice) async {
    final pending = _pending;
    if (pending == null) {
      return;
    }

    _dropAsk();
    if (choice == .no) {
      _emit();
      await _send(pending.deviceId, _state(.CONTROL_STATUS_DENIED));
      return;
    }

    if (choice == .always) {
      await _settings.setControlAlways(pending.deviceId, true);
    }

    final shown = _shownTo;
    if (shown == null || shown.deviceId != pending.deviceId) {
      _emit();
      return;
    }

    await _allow(shown);
  }

  /// Stop on this phone: the computer goes back to watching.
  Future<void> stop() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await _endControl();
    _emit();
    await _send(controller.deviceId, _state(.CONTROL_STATUS_STOPPED));
  }

  /// The computer gives control back.
  Future<void> onRelease(String deviceId) async {
    if (_controller?.deviceId != deviceId) {
      return;
    }

    await _endControl();
    _emit();
    await _sendState(deviceId);
  }

  /// What the computer did, carried out in order. Dropped unless that
  /// computer controls this phone right now.
  void onInput(String deviceId, ControlInput input) {
    if (_controller?.deviceId != deviceId) {
      return;
    }

    final events = input.events.take(maxEventsPerBatch).toList();
    _inputs = _inputs.then((_) => _apply(deviceId, events));
  }

  Future<void> dispose() async {
    _dropAsk();
    await _pathChanges?.cancel();
    await _endControl();
    await _phone.dispose();
    await _changes.close();
  }

  Future<void> _apply(String deviceId, List<ControlEvent> events) async {
    for (final event in events) {
      if (_controller?.deviceId != deviceId) {
        return;
      }

      try {
        await _applyOne(event);
      } on Object catch (error) {
        printWarning('A control event could not be carried out', error);
      }
    }
  }

  Future<void> _applyOne(ControlEvent event) async {
    if (event.hasPointer()) {
      await _pointer(event.pointer);
      return;
    }

    if (event.hasKey()) {
      final key = event.key;
      final keyCode = PhoneInputs.keyCodeOf(key.key);
      if (keyCode == null) {
        return;
      }

      await _phone.key(
        keyCode,
        down: key.pressed,
        metaState: PhoneInputs.metaStateOf(key.modifiers),
      );
      return;
    }

    if (event.hasText() && event.text.text.isNotEmpty) {
      await _phone.text(event.text.text);
      return;
    }

    if (event.hasButton()) {
      if (PhoneInputs.buttonOf(event.button.button) case final button?) {
        await _phone.press(button);
      }
    }
  }

  Future<void> _pointer(PointerInput pointer) async {
    final x = pointer.x.clamp(0, 1).toDouble();
    final y = pointer.y.clamp(0, 1).toDouble();
    final action = switch (pointer.phase) {
      .TOUCH_PHASE_DOWN => TouchAction.down,
      .TOUCH_PHASE_MOVE => TouchAction.move,
      .TOUCH_PHASE_UP => TouchAction.up,
      .TOUCH_PHASE_CANCEL => TouchAction.cancel,
      _ => null,
    };
    if (action != null) {
      await _phone.touch(action, x, y);
      return;
    }

    if (pointer.phase == .TOUCH_PHASE_SCROLL) {
      await _phone.scroll(
        x,
        y,
        horizontal: pointer.scrollX,
        vertical: pointer.scrollY,
      );
    }
  }

  Future<void> _allow(ControlRequest shown) async {
    await _phone.arm();
    _controller = ControlRequest(
      deviceId: shown.deviceId,
      deviceName: shown.deviceName,
      askedAt: _clock(),
    );
    _emit();
    await _sendState(shown.deviceId);
  }

  Future<void> _endControl() async {
    if (_controller == null) {
      return;
    }

    _controller = null;
    await _phone.disarm();
  }

  void _dropAsk() {
    _askTimer?.cancel();
    _askTimer = null;
    _pending = null;
  }

  Future<void> _timedOut(ControlRequest pending) async {
    if (!identical(_pending, pending)) {
      return;
    }

    _dropAsk();
    _emit();
    await _send(pending.deviceId, _state(.CONTROL_STATUS_TIMED_OUT));
  }

  /// Ferret control was turned on or off, or the power-ups came or went.
  Future<void> _onPathChanged() async {
    final shown = _shownTo;
    if (path == .none) {
      _dropAsk();
      await _endControl();
    }

    _emit();
    if (shown != null) {
      await _sendState(shown.deviceId);
    }
  }

  Future<void> _sendState(String deviceId) =>
      _send(deviceId, _stateFor(deviceId));

  ControlState _stateFor(String deviceId) {
    if (!isSupported) {
      return ControlState(status: .CONTROL_STATUS_UNSUPPORTED);
    }

    if (_controller?.deviceId == deviceId) {
      return _state(.CONTROL_STATUS_ALLOWED);
    }

    if (_pending case final pending? when pending.deviceId == deviceId) {
      final left = askTimeout - _clock().difference(pending.askedAt);
      return _state(.CONTROL_STATUS_ASKING)
        ..timeoutSeconds = switch (left.isNegative) {
          true => 0,
          false => (left.inMilliseconds + 999) ~/ 1000,
        };
    }

    if (path == .none) {
      return ControlState(status: .CONTROL_STATUS_NEEDS_SETUP);
    }

    return _state(.CONTROL_STATUS_CAN_ASK);
  }

  ControlState _state(ControlStatus status) => ControlState(
    status: status,
    kinds: _phone.abilities.map(PhoneInputs.kindOf),
    buttons: _phone.buttons.map(PhoneInputs.buttonToProto),
  );

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
