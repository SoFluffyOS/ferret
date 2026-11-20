import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/services/capture_translator.dart';
import 'package:remote_input/services/input_batcher.dart';
import 'package:remote_input/services/input_codec.dart';

/// This device's side when it controls another, such as a phone used as a
/// touchpad or a Mac lending its keyboard and mouse ([mode]): asks for
/// control, waits for the owner's answer, then sends input in small
/// batches without waiting for replies.
class ControlClient implements InputSink {
  ControlClient({
    required FeatureHost host,
    required String featureId,
    this.mode = .CONTROL_MODE_UNSPECIFIED,
    this.requestTimeout = const Duration(seconds: 10),
    this.consentGrace = const Duration(seconds: 15),
    this.batchInterval = const Duration(milliseconds: 16),
    DateTime Function()? clock,
  }) : _host = host,
       _featureId = featureId,
       _clock = clock ?? DateTime.now;

  /// What kind of controller this device is, told to the other device.
  final ControlMode mode;

  final Duration requestTimeout;

  /// How much longer than the other device's own consent timeout to wait,
  /// in case its "no answer" message got lost.
  final Duration consentGrace;

  final Duration batchInterval;

  final FeatureHost _host;
  final String _featureId;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final Map<String, OutgoingControl> _last = {};

  OutgoingControl? _current;
  InputBatcher? _batcher;
  Timer? _consentTimer;

  /// The control this device asked for or holds, if any.
  OutgoingControl? get current => _current;

  /// How the last attempt to control [deviceId] went.
  OutgoingControl? lastFor(String deviceId) => _last[deviceId];

  Stream<void> get changes => _changes.stream;

  /// Asks [deviceId] for control. The answer is in [current] and [changes].
  Future<OutgoingControl> start(String deviceId) async {
    if (_current case final current? when current.phase.isLive) {
      if (current.deviceId == deviceId) {
        return current;
      }

      await stop();
    }

    final session = _host.sessionFor(deviceId);
    final control = OutgoingControl(
      deviceId: deviceId,
      deviceName: _host.displayNameOf(deviceId),
      phase: .requesting,
    );
    if (session == null) {
      return _set(control.copyWith(phase: .unreachable));
    }

    if (!session.supports(_featureId)) {
      return _set(control.copyWith(phase: .denied, denial: .unsupported));
    }

    _set(control);
    try {
      final reply = await session.request(
        _featureId,
        ControlRequest(version: InputCodec.protocolVersion, mode: mode),
        timeout: requestTimeout,
      );
      return _onReply(session, control, reply);
    } on RemoteErrorException catch (error) {
      printWarning('Asking $deviceId for control failed', error);
      final denial = switch (error.code) {
        .ERROR_CODE_UNSUPPORTED => OutgoingDenial.unsupported,
        _ => null,
      };
      return _failed(control, denial);
    } on Object catch (error) {
      printWarning('Asking $deviceId for control failed', error);
      return _failed(control, null);
    }
  }

  /// Ends control, or stops asking. Tells the other device.
  Future<void> stop() async {
    final current = _current;
    if (current == null) {
      return;
    }

    final wasLive = current.phase.isLive;
    _batcher?.flush();
    _end();
    _current = null;
    _emit();
    if (!wasLive) {
      return;
    }

    await _send(
      current.deviceId,
      ControlStop(reason: .STOP_REASON_CONTROLLER_DONE),
    );
  }

  /// Forgets an attempt that ended, so the page and card stop showing it.
  void dismiss() {
    if (_current case final current? when !current.phase.isLive) {
      _current = null;
      _emit();
    }
  }

  @override
  void move(double dx, double dy) => _batcher?.move(dx, dy);

  @override
  void scroll(double dx, double dy) => _batcher?.scroll(dx, dy);

  /// Sends [event] now, after any motion waiting.
  @override
  void add(InputEvent event) => _batcher?.add(event);

  /// Sends whatever waits now.
  void flush() => _batcher?.flush();

  void click(PointerButton button) {
    _batcher
      ?..add(InputCodec.button(button, pressed: true))
      ..add(InputCodec.button(button, pressed: false));
  }

  void press(PointerButton button) =>
      _batcher?.add(InputCodec.button(button, pressed: true));

  void release(PointerButton button) =>
      _batcher?.add(InputCodec.button(button, pressed: false));

  /// Presses and releases [key] with [modifiers] held.
  void tapKey(InputKey key, {Set<KeyModifier> modifiers = const {}}) {
    _batcher
      ?..add(InputCodec.key(key, pressed: true, modifiers: modifiers))
      ..add(InputCodec.key(key, pressed: false, modifiers: modifiers));
  }

  void type(String text) {
    if (text.isEmpty) {
      return;
    }

    _batcher?.add(InputCodec.text(text));
  }

  void onGrant(Session session, ControlGrant grant) {
    final current = _current;
    if (current == null ||
        current.deviceId != session.remoteDeviceId ||
        current.phase != .waitingForConsent) {
      return;
    }

    _activate(session, current, always: grant.always);
  }

  void onDeny(Session session, ControlDeny deny) {
    final current = _current;
    if (current == null ||
        current.deviceId != session.remoteDeviceId ||
        current.phase != .waitingForConsent) {
      return;
    }

    _end();
    _set(current.copyWith(phase: .denied, denial: _denialOf(deny.reason)));
  }

  void onStop(Session session, ControlStop stop) {
    final current = _current;
    if (current == null ||
        current.deviceId != session.remoteDeviceId ||
        !current.phase.isLive) {
      return;
    }

    final reason = switch (stop.reason) {
      .STOP_REASON_IDLE => OutgoingStop.idle,
      .STOP_REASON_REVOKED => OutgoingStop.revoked,
      .STOP_REASON_FAILED => OutgoingStop.failed,
      _ => OutgoingStop.stoppedOnHost,
    };
    _end();
    _set(current.copyWith(phase: .stopped, stop: reason));
  }

  void onSessionClosed(String deviceId) {
    final current = _current;
    if (current == null ||
        current.deviceId != deviceId ||
        !current.phase.isLive) {
      return;
    }

    _end();
    _set(current.copyWith(phase: .lostConnection));
  }

  Future<void> dispose() async {
    await stop();
    await _changes.close();
  }

  OutgoingControl _onReply(
    Session session,
    OutgoingControl control,
    Envelope reply,
  ) {
    if (!identical(_current, control)) {
      _letGoIfGranted(control.deviceId, reply);
      return _current ?? control;
    }

    if (payloadOf(reply, ControlGrant.new) case final grant?) {
      return _activate(session, control, always: grant.always);
    }

    if (payloadOf(reply, ControlDeny.new) case final deny?) {
      return _set(
        control.copyWith(phase: .denied, denial: _denialOf(deny.reason)),
      );
    }

    if (payloadOf(reply, ControlPending.new) case final pending?) {
      final waiting = _set(control.copyWith(phase: .waitingForConsent));
      final wait = Duration(seconds: pending.timeoutSeconds) + consentGrace;
      _consentTimer = Timer(wait, () => _onConsentOverdue(waiting));
      return waiting;
    }

    return _failed(control, null);
  }

  /// The person gave up before the answer came; a yes that arrives late
  /// must not leave the other device thinking it is controlled.
  void _letGoIfGranted(String deviceId, Envelope reply) {
    final granted =
        payloadOf(reply, ControlGrant.new) != null ||
        payloadOf(reply, ControlPending.new) != null;
    if (!granted) {
      return;
    }

    unawaited(
      _send(deviceId, ControlStop(reason: .STOP_REASON_CONTROLLER_DONE)),
    );
  }

  OutgoingControl _activate(
    Session session,
    OutgoingControl control, {
    required bool always,
  }) {
    _consentTimer?.cancel();
    _consentTimer = null;
    _batcher?.dispose();
    _batcher = InputBatcher(
      interval: batchInterval,
      clock: _clock,
      send: (events) => unawaited(
        _send(session.remoteDeviceId, InputBatch(events: events)),
      ),
    );
    return _set(control.copyWith(phase: .active, always: always));
  }

  void _onConsentOverdue(OutgoingControl waiting) {
    if (!identical(_current, waiting)) {
      return;
    }

    _set(waiting.copyWith(phase: .denied, denial: .timeout));
    unawaited(
      _send(
        waiting.deviceId,
        ControlStop(reason: .STOP_REASON_CONTROLLER_DONE),
      ),
    );
  }

  OutgoingControl _failed(OutgoingControl control, OutgoingDenial? denial) {
    if (!identical(_current, control)) {
      return _current ?? control;
    }

    if (denial != null) {
      return _set(control.copyWith(phase: .denied, denial: denial));
    }

    return _set(control.copyWith(phase: .unreachable));
  }

  OutgoingDenial _denialOf(DenyReason reason) => switch (reason) {
    .DENY_REASON_TIMEOUT => .timeout,
    .DENY_REASON_BUSY => .busy,
    .DENY_REASON_NEEDS_PERMISSION => .needsPermission,
    .DENY_REASON_UNSUPPORTED => .unsupported,
    .DENY_REASON_TURNED_OFF => .turnedOff,
    .DENY_REASON_VERSION => .version,
    _ => .denied,
  };

  void _end() {
    _consentTimer?.cancel();
    _consentTimer = null;
    _batcher?.dispose();
    _batcher = null;
  }

  OutgoingControl _set(OutgoingControl control) {
    _current = control;
    _last[control.deviceId] = control;
    _emit();
    return control;
  }

  Future<void> _send(String deviceId, GeneratedMessage message) async {
    final session = _host.sessionFor(deviceId);
    if (session == null) {
      return;
    }

    try {
      await session.send(_featureId, message);
    } on Object catch (error) {
      printWarning('Remote input message to $deviceId failed', error);
    }
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
