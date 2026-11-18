import 'package:core/core.dart';

/// The settings of Calls, kept under `calls.*`.
class CallsSettings {
  const CallsSettings(this._settings);

  static const enabledKey = 'calls.enabled';
  static const showIncomingKey = 'calls.show_incoming';

  final SettingsStore _settings;

  /// On a phone: share its calls with the person's other devices. Off until
  /// they set it up.
  bool get enabled => _settings.get<bool>(enabledKey) ?? false;

  /// On a computer: show a notice when a phone rings.
  bool get showIncoming => _settings.get<bool>(showIncomingKey) ?? true;

  Future<void> setEnabled(bool value) => _settings.set(enabledKey, value);

  Future<void> setShowIncoming(bool value) =>
      _settings.set(showIncomingKey, value);

  /// Whether [key] is one of the settings above.
  static bool owns(String key) => key == enabledKey || key == showIncomingKey;
}
