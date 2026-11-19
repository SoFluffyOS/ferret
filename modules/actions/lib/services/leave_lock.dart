import 'dart:async';

import 'package:actions/models/models.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_actions/ferret_actions.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:protocol/protocol.dart';

/// Locks this computer when a phone its owner chose leaves: its session
/// dropped without a goodbye and it stayed gone for a few minutes. A phone
/// that paused or quit Ferret says goodbye first, and one that comes back
/// within the wait (the Wi-Fi hopped, it is reconnecting) never counts.
/// Nobody at the keyboard for [idleNeeded] is required too, so a person
/// at the desk whose phone died isn't locked out, and the owner gets
/// [countdownLength] to cancel. It never unlocks.
class LeaveLock {
  LeaveLock({
    required FeatureHost host,
    required ActionsSettings settings,
    required ScreenLocker locker,
    required InputIdle idle,
    DateTime Function()? clock,
    this.idleNeeded = const Duration(minutes: 1),
    this.countdownLength = const Duration(seconds: 10),
    this.recheckEvery = const Duration(seconds: 30),
    this.minute = const Duration(minutes: 1),
  }) : _host = host,
       _settings = settings,
       _locker = locker,
       _idle = idle,
       _clock = clock ?? DateTime.now;

  /// How many locks Activity keeps in memory.
  static const recentLength = 10;

  /// How long nobody may have touched the keyboard or mouse before it
  /// locks.
  final Duration idleNeeded;

  /// How long the owner has to cancel.
  final Duration countdownLength;

  /// How often a phone that is still gone is looked at again, while
  /// someone is at the computer or the phone is reconnecting.
  final Duration recheckEvery;

  /// How long one minute of the wait in Settings lasts. Renders shorten
  /// it.
  final Duration minute;

  final FeatureHost _host;
  final ActionsSettings _settings;
  final ScreenLocker _locker;
  final InputIdle _idle;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final Map<String, Timer> _waits = {};
  final List<LeaveLockRecord> _recent = [];

  StreamSubscription<String>? _settingsSubscription;
  bool Function(String deviceId) _isReconnecting = _never;
  LeaveCountdown? _countdown;
  Timer? _countdownTimer;
  bool _disposed = false;

  /// Fires when anything the UI shows may have changed.
  Stream<void> get changes => _changes.stream;

  /// The lock about to happen, or null.
  LeaveCountdown? get countdown => _countdown;

  /// Locks after a phone left, newest first, for Activity.
  List<LeaveLockRecord> get recent => List.unmodifiable(_recent);

  /// Whether this computer can lock its screen at all.
  bool get isSupported => _locker.isSupported;

  /// Whether a phone on [platform] can be watched. Android keeps Ferret
  /// connected in the background; iOS stops it, so an iPhone would look
  /// gone each time Ferret left its screen.
  static bool canWatch(Platform platform) => platform == .PLATFORM_ANDROID;

  void start() {
    _settingsSubscription = _settings.changes.listen(_onSettingChanged);
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final wait in _waits.values) {
      wait.cancel();
    }

    _waits.clear();
    _countdownTimer?.cancel();
    await _settingsSubscription?.cancel();
    await _changes.close();
  }

  /// Asks [isReconnecting] before each look, so a phone the engine still
  /// redials waits a little longer.
  void watchReconnecting(bool Function(String deviceId) isReconnecting) {
    _isReconnecting = isReconnecting;
  }

  /// A phone that came back is not gone: its wait and countdown stop.
  void onSessionOpened(Session session) {
    final deviceId = session.remoteDeviceId;
    _waits.remove(deviceId)?.cancel();
    if (_countdown?.deviceId == deviceId) {
      _stopCountdown();
    }
  }

  /// A drop without a goodbye starts the wait. A goodbye means Ferret was
  /// paused or quit there, which says nothing about where the phone is.
  void onSessionClosed(Session session) {
    final deviceId = session.remoteDeviceId;
    if (!_settings.locksWhenGone(deviceId) || session.remoteGoodbye != null) {
      return;
    }

    _wait(deviceId, minute * _settings.lockAfterMinutes);
  }

  /// The owner said no: this computer stays unlocked until the phone
  /// comes back and leaves again.
  void cancel() {
    final countdown = _countdown;
    if (countdown == null) {
      return;
    }

    _stopCountdown();
    _record(countdown, .cancelled);
  }

  void dismissRecord(String id) {
    _recent.removeWhere((record) => record.id == id);
    _emit();
  }

  void _wait(String deviceId, Duration delay) {
    _waits.remove(deviceId)?.cancel();
    _waits[deviceId] = Timer(delay, () => unawaited(_check(deviceId)));
  }

  Future<void> _check(String deviceId) async {
    _waits.remove(deviceId);
    if (!_isStillGone(deviceId) || _host.localPresence.away) {
      return;
    }

    if (_isReconnecting(deviceId) || _countdown != null) {
      _wait(deviceId, recheckEvery);
      return;
    }

    final idle = await _idleTime();
    if (!_isStillGone(deviceId) || _countdown != null) {
      return;
    }

    if (idle != null && idle < idleNeeded) {
      _wait(deviceId, recheckEvery);
      return;
    }

    _startCountdown(deviceId);
  }

  bool _isStillGone(String deviceId) =>
      !_disposed &&
      _host.sessionFor(deviceId) == null &&
      _host.trustStore[deviceId] != null &&
      _settings.locksWhenGone(deviceId);

  /// Unknown reads as idle: the countdown still gives the owner a way out.
  Future<Duration?> _idleTime() async {
    try {
      return await _idle.idleTime();
    } on Object catch (error) {
      printWarning('Reading idle time failed', error);
      return null;
    }
  }

  void _startCountdown(String deviceId) {
    final startedAt = _clock();
    final countdown = LeaveCountdown(
      deviceId: deviceId,
      deviceName: _host.displayNameOf(deviceId),
      startedAt: startedAt,
      endsAt: startedAt.add(countdownLength),
    );
    _countdown = countdown;
    _countdownTimer = Timer(
      countdownLength,
      () => unawaited(_lock(countdown)),
    );
    _emit();
  }

  Future<void> _lock(LeaveCountdown countdown) async {
    _countdown = null;
    _countdownTimer = null;
    if (!_isStillGone(countdown.deviceId)) {
      _emit();
      return;
    }

    final locked = await _lockScreen();
    _record(countdown, switch (locked) {
      true => .locked,
      false => .failed,
    });
  }

  Future<bool> _lockScreen() async {
    try {
      return await _locker.lock();
    } on Object catch (error) {
      printWarning('Locking after a phone left failed', error);
      return false;
    }
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdown = null;
    _emit();
  }

  void _record(LeaveCountdown countdown, LeaveLockOutcome outcome) {
    if (_disposed) {
      return;
    }

    _recent.insert(
      0,
      LeaveLockRecord(
        deviceId: countdown.deviceId,
        deviceName: countdown.deviceName,
        at: _clock(),
        outcome: outcome,
      ),
    );
    if (_recent.length > recentLength) {
      _recent.removeLast();
    }

    _emit();
  }

  void _onSettingChanged(String key) {
    if (key != ActionsSettings.lockWhenGoneKey) {
      return;
    }

    for (final deviceId in [..._waits.keys]) {
      if (!_settings.locksWhenGone(deviceId)) {
        _waits.remove(deviceId)?.cancel();
      }
    }

    if (_countdown case final countdown?
        when !_settings.locksWhenGone(countdown.deviceId)) {
      _stopCountdown();
    }
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  static bool _never(String deviceId) => false;
}
