import 'package:core/core.dart';
import 'package:remote_input/models/control_record.dart';

/// Remote input's settings, stored under `remote_input.*`.
class RemoteInputSettings {
  const RemoteInputSettings(this._store);

  static const enabledKey = 'remote_input.enabled';
  static const allowedDevicesKey = 'remote_input.allowed_devices';
  static const historyKey = 'remote_input.history';
  static const touchpadSpeedKey = 'remote_input.touchpad_speed';
  static const naturalScrollKey = 'remote_input.natural_scroll';

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

  bool isAlwaysAllowed(String deviceId) => allowedDevices.contains(deviceId);

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

  Future<void> setEnabled(bool value) => _store.set(enabledKey, value);

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
