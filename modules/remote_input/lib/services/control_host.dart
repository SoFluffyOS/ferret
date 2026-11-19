import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/services/input_codec.dart';

/// This computer's side of remote input: asks its owner the first time a
/// device wants control, lets one device control it at a time, injects its
/// input, and writes an audit line when it ends. Stop cuts it off at once.
class ControlHost {
  ControlHost({
    required FeatureHost host,
    required String featureId,
    required InputInjector injector,
    required RemoteInputSettings settings,
    ScreenLocker? locker,
    DateTime Function()? clock,
    this.consentTimeout = const Duration(seconds: 60),
    this.idleTimeout = const Duration(minutes: 10),
    this.denyCooldown = const Duration(seconds: 30),
  }) : _host = host,
       _featureId = featureId,
       _injector = injector,
       _locker = locker ?? const UnsupportedScreenLocker(),
       _settings = settings,
       _clock = clock ?? DateTime.now;

  /// How long the owner has to answer before the request is denied.
  final Duration consentTimeout;

  /// Control ends on its own after this long without any input.
  final Duration idleTimeout;

  /// After "Don't allow", the same device is turned away this long, so it
  /// can't flood the owner with prompts.
  final Duration denyCooldown;

  /// "Not controlling" answers to stray input, at most this often.
  static const _strayNoticeGap = Duration(seconds: 1);

  final FeatureHost _host;
  final String _featureId;
  final InputInjector _injector;
  final ScreenLocker _locker;
  final RemoteInputSettings _settings;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final Map<String, DateTime> _deniedUntil = {};
  final Map<String, DateTime> _strayNoticeAt = {};

  InjectorStatus _status = const .unavailable(.failed);
  ConsentRequest? _pending;
  Completer<LockResult>? _lockAnswer;
  ActiveControl? _active;
  PermissionAsk? _permissionAsk;
  ControlRecord? _lastRecord;
  Timer? _consentTimer;
  Timer? _idleTimer;
  DateTime _lastInputAt = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _injecting = Future.value();

  /// Whether this computer can lock its screen for another device.
  bool get canLock => _locker.isSupported;

  /// Whether input can be injected, as last checked.
  InjectorStatus get status => _status;

  /// Being controlled is on and worked before, and input can't be injected
  /// now, such as after the system access was taken away. False when it
  /// was simply never set up.
  bool get lostAccess =>
      _settings.enabled && _settings.hadAccess && !_status.isReady;

  /// A device waiting for the owner's answer.
  ConsentRequest? get pending => _pending;

  /// The device controlling this computer right now.
  ActiveControl? get active => _active;

  /// A device asked while the system permission was missing.
  PermissionAsk? get permissionAsk => _permissionAsk;

  /// The most recent time of being controlled since the app started, until
  /// dismissed.
  ControlRecord? get lastRecord => _lastRecord;

  Stream<void> get changes => _changes.stream;

  Future<void> start() async {
    await refreshStatus();
  }

  Future<InjectorStatus> refreshStatus() async {
    final previous = _status;
    final asked = _permissionAsk != null;
    try {
      _status = await _injector.status();
    } on Object catch (error) {
      printWarning('Could not check remote input access', error);
      _status = const .unavailable(.failed);
    }

    if (_status.isReady) {
      _permissionAsk = null;
    }

    _rememberAccess();
    if (_status != previous || (asked && _permissionAsk == null)) {
      _emit();
    }

    return _status;
  }

  /// Shows the system prompt where there is one. macOS shows it only the
  /// first time, so when access is still off, opens the settings page.
  Future<InjectorStatus> requestAccess() async {
    try {
      _status = await _injector.requestAccess();
      if (_status.state == .needsPermission) {
        await _injector.openAccessSettings();
      }
    } on Object catch (error) {
      printWarning('Could not ask for remote input access', error);
    }

    _rememberAccess();
    _emit();
    return _status;
  }

  Future<void> openAccessSettings() => _injector.openAccessSettings();

  /// Answers a device asking for control: grant, deny, or "asking the
  /// owner" with the answer sent later.
  Future<GeneratedMessage> onRequest(
    Session session,
    ControlRequest request,
  ) async {
    final deviceId = session.remoteDeviceId;
    final deviceName = _host.displayNameOf(deviceId);

    if (request.version > InputCodec.protocolVersion) {
      return ControlDeny(reason: .DENY_REASON_VERSION);
    }

    if (!_settings.enabled) {
      return ControlDeny(reason: .DENY_REASON_TURNED_OFF);
    }

    final status = await refreshStatus();
    if (status.state == .unavailable) {
      return ControlDeny(reason: .DENY_REASON_UNSUPPORTED);
    }

    if (status.state == .needsPermission) {
      _permissionAsk = PermissionAsk(
        deviceId: deviceId,
        deviceName: deviceName,
        askedAt: _clock(),
      );
      _emit();
      return ControlDeny(reason: .DENY_REASON_NEEDS_PERMISSION);
    }

    if (_active case final active?) {
      if (active.deviceId == deviceId) {
        return ControlGrant(
          version: InputCodec.protocolVersion,
          always: active.always,
        );
      }

      return ControlDeny(reason: .DENY_REASON_BUSY);
    }

    if (_pending case final pending?) {
      if (pending.deviceId == deviceId && pending.kind == .control) {
        return ControlPending(timeoutSeconds: _secondsLeft(pending));
      }

      return ControlDeny(reason: .DENY_REASON_BUSY);
    }

    if (_settings.isAlwaysAllowed(deviceId)) {
      _activate(deviceId, deviceName, always: true);
      return ControlGrant(version: InputCodec.protocolVersion, always: true);
    }

    final deniedUntil = _deniedUntil[deviceId];
    if (deniedUntil != null && _clock().isBefore(deniedUntil)) {
      return ControlDeny(reason: .DENY_REASON_DENIED);
    }

    final pending = ConsentRequest(
      deviceId: deviceId,
      deviceName: deviceName,
      askedAt: _clock(),
    );
    _pending = pending;
    _consentTimer = Timer(consentTimeout, () => _onConsentTimeout(pending));
    _emit();
    return ControlPending(timeoutSeconds: consentTimeout.inSeconds);
  }

  /// The owner's answer to [pending].
  Future<void> answer(ConsentChoice choice) async {
    final pending = _pending;
    if (pending == null) {
      return;
    }

    if (pending.kind == .lock) {
      await _answerLock(pending, choice);
      return;
    }

    _clearPending();
    final deviceId = pending.deviceId;
    switch (choice) {
      case .deny:
        _deniedUntil[deviceId] = _clock().add(denyCooldown);
        _emit();
        await _send(deviceId, ControlDeny(reason: .DENY_REASON_DENIED));
      case .allowOnce:
        _activate(deviceId, pending.deviceName, always: false);
        await _send(
          deviceId,
          ControlGrant(version: InputCodec.protocolVersion),
        );
      case .always:
        await _settings.allow(deviceId);
        _activate(deviceId, pending.deviceName, always: true);
        await _send(
          deviceId,
          ControlGrant(version: InputCodec.protocolVersion, always: true),
        );
    }
  }

  /// Locks this computer for [session]'s device: right away when its owner
  /// allowed that device before, otherwise after asking.
  Future<LockReply> onLockRequest(Session session) async {
    final deviceId = session.remoteDeviceId;

    if (!_settings.enabled) {
      return LockReply(result: .LOCK_RESULT_TURNED_OFF);
    }

    if (!_locker.isSupported) {
      return LockReply(result: .LOCK_RESULT_FAILED);
    }

    if (_settings.mayLock(deviceId)) {
      return LockReply(result: await _lockNow());
    }

    if (_pending != null) {
      return LockReply(result: .LOCK_RESULT_BUSY);
    }

    final deniedUntil = _deniedUntil[deviceId];
    if (deniedUntil != null && _clock().isBefore(deniedUntil)) {
      return LockReply(result: .LOCK_RESULT_DENIED);
    }

    final pending = ConsentRequest(
      deviceId: deviceId,
      deviceName: _host.displayNameOf(deviceId),
      askedAt: _clock(),
      kind: .lock,
    );
    final answer = Completer<LockResult>();
    _pending = pending;
    _lockAnswer = answer;
    _consentTimer = Timer(consentTimeout, () => _onConsentTimeout(pending));
    _emit();
    return LockReply(result: await answer.future);
  }

  Future<void> _answerLock(ConsentRequest pending, ConsentChoice choice) async {
    final answer = _takeLockAnswer();
    _clearPending();
    _emit();
    final result = switch (choice) {
      .deny => LockResult.LOCK_RESULT_DENIED,
      .allowOnce || .always => null,
    };
    if (result != null) {
      _deniedUntil[pending.deviceId] = _clock().add(denyCooldown);
      answer?.complete(result);
      return;
    }

    if (choice == .always) {
      await _settings.allowLock(pending.deviceId);
    }

    answer?.complete(await _lockNow());
  }

  Future<LockResult> _lockNow() async {
    try {
      if (await _locker.lock()) {
        return .LOCK_RESULT_LOCKED;
      }
    } on Object catch (error) {
      printWarning('Locking the screen failed', error);
    }

    return .LOCK_RESULT_FAILED;
  }

  /// Input from [session]: injected when it is the controlling device.
  Future<void> onBatch(Session session, InputBatch batch) {
    final deviceId = session.remoteDeviceId;
    if (_active?.deviceId != deviceId) {
      _answerStray(session);
      return Future.value();
    }

    _lastInputAt = _clock();
    final actions = InputCodec.actionsOf(batch);
    if (actions.isEmpty) {
      return Future.value();
    }

    final injecting = _injecting.then((_) => _inject(deviceId, actions));
    _injecting = injecting;
    return injecting;
  }

  /// The other device ended control, or gave up asking.
  Future<void> onStop(Session session) async {
    final deviceId = session.remoteDeviceId;
    if (_pending?.deviceId == deviceId) {
      _clearPending();
      _emit();
      return;
    }

    if (_active?.deviceId == deviceId) {
      await _end(.controllerDone);
    }
  }

  Future<void> onSessionClosed(String deviceId) async {
    if (_pending?.deviceId == deviceId) {
      _clearPending();
      _emit();
    }

    if (_active?.deviceId == deviceId) {
      await _end(.lostConnection);
    }
  }

  /// Stop on this computer: cuts the controller off right away.
  Future<void> stop() async {
    if (_active == null) {
      return;
    }

    await _end(.stoppedHere, notify: .STOP_REASON_STOPPED_ON_HOST);
  }

  /// Forgets "Always" for [deviceId], and ends its control if it has it.
  Future<void> revoke(String deviceId) async {
    await _settings.revoke(deviceId);
    if (_active?.deviceId == deviceId) {
      await _end(.revoked, notify: .STOP_REASON_REVOKED);
    }

    _emit();
  }

  /// Turns remote input on or off; off ends any control and request.
  Future<void> setEnabled(bool enabled) async {
    await _settings.setEnabled(enabled);
    if (enabled) {
      _emit();
      return;
    }

    if (_pending case final pending?) {
      final lockAnswer = _takeLockAnswer();
      _clearPending();
      lockAnswer?.complete(.LOCK_RESULT_TURNED_OFF);
      if (pending.kind == .control) {
        await _send(
          pending.deviceId,
          ControlDeny(reason: .DENY_REASON_TURNED_OFF),
        );
      }
    }

    if (_active != null) {
      await _end(.revoked, notify: .STOP_REASON_REVOKED);
    }

    _emit();
  }

  void _rememberAccess() {
    if (!_status.isReady || _settings.hadAccess) {
      return;
    }

    unawaited(_settings.setHadAccess(true));
  }

  void dismissRecord() {
    _lastRecord = null;
    _emit();
  }

  void dismissPermissionAsk() {
    _permissionAsk = null;
    _emit();
  }

  Future<void> clearHistory() async {
    await _settings.clearHistory();
    _lastRecord = null;
    _emit();
  }

  Future<void> dispose() async {
    _clearPending();
    if (_active != null) {
      await _end(.lostConnection, notify: .STOP_REASON_STOPPED_ON_HOST);
    }

    _idleTimer?.cancel();
    await _injector.dispose();
    await _changes.close();
  }

  void _activate(String deviceId, String deviceName, {required bool always}) {
    final now = _clock();
    _active = ActiveControl(
      deviceId: deviceId,
      deviceName: deviceName,
      startedAt: now,
      always: always,
    );
    _lastInputAt = now;
    _deniedUntil.remove(deviceId);
    if (_permissionAsk?.deviceId == deviceId) {
      _permissionAsk = null;
    }

    _scheduleIdleCheck(idleTimeout);
    _emit();
  }

  Future<void> _inject(String deviceId, List<InputAction> actions) async {
    if (_active?.deviceId != deviceId) {
      return;
    }

    try {
      await _injector.inject(actions);
    } on Object catch (error) {
      printWarning('Injecting remote input failed', error);
      final status = await refreshStatus();
      if (!status.isReady && _active?.deviceId == deviceId) {
        await _end(.failed, notify: .STOP_REASON_FAILED);
      }
    }
  }

  /// Ends control: lets go of every key and button first, then records it.
  Future<void> _end(ControlEnd end, {StopReason? notify}) async {
    final active = _active;
    if (active == null) {
      return;
    }

    _active = null;
    _idleTimer?.cancel();
    _idleTimer = null;
    final record = ControlRecord(
      deviceId: active.deviceId,
      deviceName: active.deviceName,
      startedAt: active.startedAt,
      endedAt: _clock(),
      end: end,
    );
    _lastRecord = record;
    _emit();

    try {
      await _injector.releaseAll();
    } on Object catch (error) {
      printWarning('Releasing held keys failed', error);
    }

    await _settings.addRecord(record);
    if (notify != null) {
      await _send(active.deviceId, ControlStop(reason: notify));
    }

    _emit();
  }

  void _onConsentTimeout(ConsentRequest pending) {
    if (!identical(_pending, pending)) {
      return;
    }

    final lockAnswer = _takeLockAnswer();
    _clearPending();
    _emit();
    if (pending.kind == .lock) {
      lockAnswer?.complete(.LOCK_RESULT_TIMEOUT);
      return;
    }

    unawaited(
      _send(pending.deviceId, ControlDeny(reason: .DENY_REASON_TIMEOUT)),
    );
  }

  void _scheduleIdleCheck(Duration after) {
    _idleTimer?.cancel();
    _idleTimer = Timer(after, _onIdleCheck);
  }

  void _onIdleCheck() {
    _idleTimer = null;
    if (_active == null) {
      return;
    }

    final idleFor = _clock().difference(_lastInputAt);
    if (idleFor < idleTimeout) {
      _scheduleIdleCheck(idleTimeout - idleFor);
      return;
    }

    unawaited(_end(.idle, notify: .STOP_REASON_IDLE));
  }

  void _answerStray(Session session) {
    final deviceId = session.remoteDeviceId;
    final now = _clock();
    final last = _strayNoticeAt[deviceId];
    if (last != null && now.difference(last) < _strayNoticeGap) {
      return;
    }

    _strayNoticeAt[deviceId] = now;
    unawaited(
      _send(deviceId, ControlStop(reason: .STOP_REASON_NOT_CONTROLLING)),
    );
  }

  Completer<LockResult>? _takeLockAnswer() {
    final answer = _lockAnswer;
    _lockAnswer = null;
    return answer;
  }

  /// A lock still waiting for an answer reads as timed out, so its device
  /// never waits for nothing.
  void _clearPending() {
    _consentTimer?.cancel();
    _consentTimer = null;
    _pending = null;
    final lockAnswer = _lockAnswer;
    _lockAnswer = null;
    if (lockAnswer != null && !lockAnswer.isCompleted) {
      lockAnswer.complete(.LOCK_RESULT_TIMEOUT);
    }
  }

  int _secondsLeft(ConsentRequest pending) {
    final left = consentTimeout - _clock().difference(pending.askedAt);
    if (left.isNegative) {
      return 0;
    }

    return left.inSeconds;
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
