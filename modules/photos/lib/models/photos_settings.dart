import 'package:core/core.dart';

/// The photos feature's choices, under `photos.*`.
class PhotosSettings {
  const PhotosSettings(this._store);

  /// On a phone: computer id to true when it may see this phone's photos.
  static const sharedWithKey = 'photos.shared_with';

  /// On a computer: phone id to true when that phone's new screenshots
  /// come here by themselves.
  static const autoScreenshotsKey = 'photos.auto_screenshots';

  final SettingsStore _store;

  Stream<String> get changes => _store.changes.where(
    (key) => key == sharedWithKey || key == autoScreenshotsKey,
  );

  /// Off until the phone's owner turns it on for [deviceId]: photos never
  /// leave the phone without that.
  bool sharesWith(String deviceId) => _read(sharedWithKey)[deviceId] == true;

  Future<void> setSharesWith(String deviceId, {required bool shared}) =>
      _write(sharedWithKey, deviceId, shared);

  /// Off until the person turns it on for the phone [deviceId].
  bool autoScreenshots(String deviceId) =>
      _read(autoScreenshotsKey)[deviceId] == true;

  Future<void> setAutoScreenshots(String deviceId, {required bool enabled}) =>
      _write(autoScreenshotsKey, deviceId, enabled);

  /// Drops what was chosen for [deviceId], such as once it is unpaired.
  Future<void> forget(String deviceId) async {
    for (final key in [sharedWithKey, autoScreenshotsKey]) {
      final stored = _read(key);
      if (!stored.containsKey(deviceId)) {
        continue;
      }

      await _store.set(key, {...stored}..remove(deviceId));
    }
  }

  Map<String, Object?> _read(String key) => switch (_store.get<Object?>(key)) {
    final Map<String, Object?> stored => stored,
    _ => const {},
  };

  Future<void> _write(String key, String deviceId, bool value) {
    final stored = {..._read(key)};
    if (value) {
      stored[deviceId] = true;
    }

    if (!value) {
      stored.remove(deviceId);
    }

    return _store.set(key, stored);
  }
}
