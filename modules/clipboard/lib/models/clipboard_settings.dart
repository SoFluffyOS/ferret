import 'package:core/core.dart';

/// The clipboard feature's settings, stored under `clipboard.*`.
class ClipboardSettings {
  const ClipboardSettings(this._store);

  static const autoSendKey = 'clipboard.auto_send';
  static const autoReceiveKey = 'clipboard.auto_receive';
  static const syncImagesKey = 'clipboard.sync_images';
  static const syncSensitiveKey = 'clipboard.sync_sensitive';
  static const maxImageBytesKey = 'clipboard.max_image_bytes';
  static const expirySecondsKey = 'clipboard.expiry_seconds';

  static const defaultMaxImageBytes = 10 * 1024 * 1024;
  static const defaultExpiry = Duration(minutes: 2);

  /// Text is never images-sized; anything longer is almost surely a mistake.
  static const maxTextBytes = 1024 * 1024;

  final SettingsStore _store;

  /// Sends what is copied here to connected devices on its own.
  bool get autoSend => _store.get<bool>(autoSendKey) ?? true;

  /// Puts what other devices send straight on this device's clipboard.
  bool get autoReceive => _store.get<bool>(autoReceiveKey) ?? true;

  bool get syncImages => _store.get<bool>(syncImagesKey) ?? true;

  /// Syncs items that password managers and other apps marked as private.
  bool get syncSensitive => _store.get<bool>(syncSensitiveKey) ?? false;

  int get maxImageBytes =>
      _store.get<int>(maxImageBytesKey) ?? defaultMaxImageBytes;

  /// How long a copy stays worth sending to a device that connects late, and
  /// how long private items stay in history.
  Duration get expiry => switch (_store.get<int>(expirySecondsKey)) {
    final int seconds when seconds > 0 => Duration(seconds: seconds),
    _ => defaultExpiry,
  };

  Future<void> setAutoSend(bool value) => _store.set(autoSendKey, value);

  Future<void> setAutoReceive(bool value) => _store.set(autoReceiveKey, value);

  Future<void> setSyncImages(bool value) => _store.set(syncImagesKey, value);

  Future<void> setSyncSensitive(bool value) =>
      _store.set(syncSensitiveKey, value);

  /// Fires with the key of each clipboard setting that changed.
  Stream<String> get changes =>
      _store.changes.where((key) => key.startsWith('clipboard.'));
}
