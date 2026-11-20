import 'package:core/core.dart';
import 'package:remote_input/models/control_record.dart';

/// Remote input's settings, stored under `remote_input.*`.
class RemoteInputSettings {
  const RemoteInputSettings(this._store);

  static const enabledKey = 'remote_input.enabled';
  static const allowedDevicesKey = 'remote_input.allowed_devices';

  /// Devices that may lock this computer without asking.
  static const lockDevicesKey = 'remote_input.lock_devices';
  static const historyKey = 'remote_input.history';
  static const touchpadSpeedKey = 'remote_input.touchpad_speed';
  static const naturalScrollKey = 'remote_input.natural_scroll';

  /// This Mac's keyboard and mouse switch to other computers with ⌃⌥→.
  static const screenSwitchKey = 'remote_input.screen_switch';

  /// The system prompts for taking the keyboard and mouse were shown once;
  /// macOS never shows them again, so the next time opens System Settings.
  static const captureAskedKey = 'remote_input.capture_asked';

  /// Set once this computer could be controlled, so access that went away
  /// later reads as lost and access never given as not set up.
  static const hadAccessKey = 'remote_input.had_access';

  /// How many past times of being controlled the history keeps.
  static const historyLength = 20;

  static const minSpeed = 0.5;
  static const maxSpeed = 3.0;

  final SettingsStore _store;

  /// Devices may ask to control this computer. On by default: each one
  /// still needs the owner's yes the first time.
  bool get enabled => _store.get<bool>(enabledKey) ?? true;

  /// Devices the owner allowed for good.
  List<String> get allowedDevices => [
    for (final id in _store.get<List<Object?>>(allowedDevicesKey) ?? const [])
      if (id case final String deviceId) deviceId,
  ];

  bool get hadAccess => _store.get<bool>(hadAccessKey) ?? false;

  bool isAlwaysAllowed(String deviceId) => allowedDevices.contains(deviceId);

  /// Devices the owner let lock this computer for good.
  List<String> get lockDevices => [
    for (final id in _store.get<List<Object?>>(lockDevicesKey) ?? const [])
      if (id case final String deviceId) deviceId,
  ];

  /// A device that may control this computer for good may lock it too.
  bool mayLock(String deviceId) =>
      lockDevices.contains(deviceId) || isAlwaysAllowed(deviceId);

  /// Past times of being controlled, newest first.
  List<ControlRecord> get history => [
    for (final json in _store.get<List<Object?>>(historyKey) ?? const [])
      ?ControlRecord.fromJson(json),
  ];

  /// How far the pointer moves for a finger's move, on the controller.
  double get touchpadSpeed {
    final speed = _store.get<num>(touchpadSpeedKey)?.toDouble() ?? 1.0;
    return speed.clamp(minSpeed, maxSpeed);
  }

  /// Two fingers moving up scroll the page down, as on a touch screen.
  bool get naturalScroll => _store.get<bool>(naturalScrollKey) ?? true;

  /// Off until the owner turns it on: the switch keys are global.
  bool get screenSwitch => _store.get<bool>(screenSwitchKey) ?? false;

  bool get captureAsked => _store.get<bool>(captureAskedKey) ?? false;

  Future<void> setEnabled(bool value) => _store.set(enabledKey, value);

  Future<void> setScreenSwitch(bool value) =>
      _store.set(screenSwitchKey, value);

  Future<void> setCaptureAsked(bool value) =>
      _store.set(captureAskedKey, value);

  Future<void> setHadAccess(bool value) => _store.set(hadAccessKey, value);

  Future<void> allow(String deviceId) async {
    final allowed = allowedDevices;
    if (allowed.contains(deviceId)) {
      return;
    }

    await _store.set(allowedDevicesKey, [...allowed, deviceId]);
  }

  Future<void> revoke(String deviceId) => _store.set(allowedDevicesKey, [
    for (final id in allowedDevices)
      if (id != deviceId) id,
  ]);

  Future<void> allowLock(String deviceId) async {
    final allowed = lockDevices;
    if (allowed.contains(deviceId)) {
      return;
    }

    await _store.set(lockDevicesKey, [...allowed, deviceId]);
  }

  Future<void> revokeLock(String deviceId) => _store.set(lockDevicesKey, [
    for (final id in lockDevices)
      if (id != deviceId) id,
  ]);

  Future<void> addRecord(ControlRecord record) => _store.set(historyKey, [
    record.toJson(),
    for (final past in history.take(historyLength - 1)) past.toJson(),
  ]);

  Future<void> clearHistory() => _store.set(historyKey, const <Object?>[]);

  Future<void> setTouchpadSpeed(double value) =>
      _store.set(touchpadSpeedKey, value.clamp(minSpeed, maxSpeed));

  Future<void> setNaturalScroll(bool value) =>
      _store.set(naturalScrollKey, value);

  /// Fires with the key of each setting that changes.
  Stream<String> get changes =>
      _store.changes.where((key) => key.startsWith('remote_input.'));
}
