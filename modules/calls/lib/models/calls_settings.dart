import 'package:core/core.dart';

/// The settings of Calls, kept under `calls.*`.
class CallsSettings {
  const CallsSettings(this._settings);

  static const enabledKey = 'calls.enabled';
  static const showIncomingKey = 'calls.show_incoming';
  static const sharingPhonesKey = 'calls.sharing_phones';

  final SettingsStore _settings;

  /// On a phone: share its calls with the person's other devices. Off until
  /// they set it up.
  bool get enabled => _settings.get<bool>(enabledKey) ?? false;

  /// On a computer: show a notice when a phone rings.
  bool get showIncoming => _settings.get<bool>(showIncomingKey) ?? true;

  /// On a computer: whether the phone [deviceId] shared its calls the last
  /// time it said, so Settings stays truthful while the phone is away.
  bool wasSharing(String deviceId) => _sharingPhones.contains(deviceId);

  Future<void> setEnabled(bool value) => _settings.set(enabledKey, value);

  Future<void> setSharing(String deviceId, bool value) async {
    final current = _sharingPhones;
    if (current.contains(deviceId) == value) {
      return;
    }

    final next = {...current};
    if (value) {
      next.add(deviceId);
    }

    if (!value) {
      next.remove(deviceId);
    }

    await _settings.set(sharingPhonesKey, next.toList()..sort());
  }

  Future<void> setShowIncoming(bool value) =>
      _settings.set(showIncomingKey, value);

  Set<String> get _sharingPhones => switch (_settings.get<List<Object?>>(
    sharingPhonesKey,
  )) {
    final List<Object?> stored => stored.whereType<String>().toSet(),
    null => const {},
  };

  /// Whether [key] is one of the settings above.
  static bool owns(String key) => key == enabledKey || key == showIncomingKey;
}
