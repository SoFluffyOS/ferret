import 'package:core/core.dart';

/// What a computer remembers about its phones, kept under `notifications.*`.
class ReceiverPreferences {
  const ReceiverPreferences(this._settings);

  static const hiddenDevicesKey = 'notifications.hidden_devices';
  static const mirroringPhonesKey = 'notifications.mirroring_phones';

  final SettingsStore _settings;

  /// Whether this computer shows what the phone [deviceId] sends. On until
  /// the person turns it off for that phone.
  bool showsFrom(String deviceId) =>
      !_stored(hiddenDevicesKey).contains(deviceId);

  /// Whether [deviceId] had mirroring on the last time it said, so Settings
  /// stays truthful while the phone is away.
  bool wasMirroring(String deviceId) =>
      _stored(mirroringPhonesKey).contains(deviceId);

  Future<void> setShowsFrom(String deviceId, bool value) =>
      _setMember(hiddenDevicesKey, deviceId, !value);

  Future<void> setMirroring(String deviceId, bool value) =>
      _setMember(mirroringPhonesKey, deviceId, value);

  Set<String> _stored(String key) => switch (_settings.get<List<Object?>>(
    key,
  )) {
    final List<Object?> stored => stored.whereType<String>().toSet(),
    null => const {},
  };

  Future<void> _setMember(String key, String deviceId, bool member) async {
    final current = _stored(key);
    if (current.contains(deviceId) == member) {
      return;
    }

    final next = {...current};
    if (member) {
      next.add(deviceId);
    }

    if (!member) {
      next.remove(deviceId);
    }

    await _settings.set(key, next.toList()..sort());
  }
}
