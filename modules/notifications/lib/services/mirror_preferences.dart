import 'package:core/core.dart';
import 'package:notifications/models/models.dart';

/// The phone's mirroring settings, kept under `notifications.*`.
class MirrorPreferences {
  const MirrorPreferences(this._settings);

  static const enabledKey = 'notifications.enabled';
  static const skipWhileUsingKey = 'notifications.skip_while_using';
  static const allowedAppsKey = 'notifications.allowed_apps';

  final SettingsStore _settings;

  /// The person turned mirroring on. Off until they set it up.
  bool get enabled => _settings.get<bool>(enabledKey) ?? false;

  /// Pause mirroring while the phone is in use. On by default.
  bool get skipWhileUsing => _settings.get<bool>(skipWhileUsingKey) ?? true;

  /// The picked apps, or null when the person never changed the defaults.
  Set<String>? get allowedApps => switch (_settings.get<List<Object?>>(
    allowedAppsKey,
  )) {
    final List<Object?> stored => stored.whereType<String>().toSet(),
    null => null,
  };

  /// Every picked app, falling back to the messaging apps.
  Set<String> get effectiveAllowedApps => allowedApps ?? MessagingApps.packages;

  bool isAllowed(String packageName) => switch (allowedApps) {
    final Set<String> picked => picked.contains(packageName),
    null => MessagingApps.contains(packageName),
  };

  Future<void> setEnabled(bool value) => _settings.set(enabledKey, value);

  Future<void> setSkipWhileUsing(bool value) =>
      _settings.set(skipWhileUsingKey, value);

  Future<void> setAllowedApps(Set<String> packages) =>
      _settings.set(allowedAppsKey, packages.toList()..sort());

  /// Turns each app in [choices] on or off, keeping the other picks.
  Future<void> setAllowed(Map<String, bool> choices) async {
    if (choices.isEmpty) {
      return;
    }

    final picked = {...effectiveAllowedApps};
    for (final MapEntry(key: packageName, value: allowed) in choices.entries) {
      if (allowed) {
        picked.add(packageName);
        continue;
      }

      picked.remove(packageName);
    }

    await setAllowedApps(picked);
  }

  /// Whether [key] is one of the settings above.
  static bool owns(String key) =>
      key == enabledKey || key == skipWhileUsingKey || key == allowedAppsKey;
}
