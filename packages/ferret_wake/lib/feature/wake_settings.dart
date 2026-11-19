import 'package:core/core.dart';

/// The wake feature's switches, on a computer.
class WakeSettings {
  const WakeSettings(this._settings);

  final SettingsStore _settings;

  static const shareKey = 'wake.share';
  static const relayKey = 'wake.relay';

  /// Whether paired devices learn this computer's MAC address so they can
  /// wake it. On by default.
  bool get shares => _settings.get<bool>(shareKey) ?? true;

  /// Whether this computer sends the magic packet when a paired device
  /// asks it to wake another device both are paired with. On by default.
  bool get relays => _settings.get<bool>(relayKey) ?? true;

  Future<void> setShares(bool shares) => _settings.set(shareKey, shares);

  Future<void> setRelays(bool relays) => _settings.set(relayKey, relays);
}
