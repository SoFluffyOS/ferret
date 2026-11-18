import 'package:core/core.dart';

/// The iPhone link's settings, stored under `iphone.*`.
class IphoneSettings {
  const IphoneSettings(this._store);

  static const enabledKey = 'iphone.enabled';
  static const deviceIdKey = 'iphone.device_id';
  static const deviceNameKey = 'iphone.device_name';
  static const showNotificationsKey = 'iphone.show_notifications';
  static const showMediaKey = 'iphone.show_media';
  static const hidePreviewsKey = 'iphone.hide_previews';

  final SettingsStore _store;

  /// Off until the person turns it on: it uses Bluetooth, and on macOS that
  /// asks for a permission.
  bool get enabled => _store.get<bool>(enabledKey) ?? false;

  /// The system's id for the chosen iPhone, only valid on this computer.
  String? get deviceId => _store.get<String>(deviceIdKey);

  String get deviceName => _store.get<String>(deviceNameKey) ?? '';

  bool get showNotifications => _store.get<bool>(showNotificationsKey) ?? true;

  bool get showMedia => _store.get<bool>(showMediaKey) ?? true;

  /// Show only which app notified, not what it said.
  bool get hidePreviews => _store.get<bool>(hidePreviewsKey) ?? false;

  Future<void> setEnabled(bool value) => _store.set(enabledKey, value);

  Future<void> setDevice({required String id, required String name}) async {
    await _store.set(deviceNameKey, name);
    await _store.set(deviceIdKey, id);
  }

  Future<void> clearDevice() async {
    await _store.set(deviceNameKey, null);
    await _store.set(deviceIdKey, null);
  }

  Future<void> setShowNotifications(bool value) =>
      _store.set(showNotificationsKey, value);

  Future<void> setShowMedia(bool value) => _store.set(showMediaKey, value);

  Future<void> setHidePreviews(bool value) =>
      _store.set(hidePreviewsKey, value);

  /// Fires with the key of each setting that changes.
  Stream<String> get changes =>
      _store.changes.where((key) => key.startsWith('iphone.'));
}
