import 'package:core/core.dart';
import 'package:notifications/models/models.dart';
import 'package:protocol/notifications.dart';

/// The phone's mirroring settings, kept under `notifications.*`.
class MirrorPreferences {
  const MirrorPreferences(this._settings);

  static const enabledKey = 'notifications.enabled';
  static const skipWhileUsingKey = 'notifications.skip_while_using';
  static const appFilterKey = 'notifications.app_filter';
  static const allowedAppsKey = 'notifications.allowed_apps';
  static const excludedAppsKey = 'notifications.excluded_apps';

  final SettingsStore _settings;

  /// The person turned mirroring on. Off until they set it up.
  bool get enabled => _settings.get<bool>(enabledKey) ?? false;

  /// Pause mirroring while the phone is in use. On by default.
  bool get skipWhileUsing => _settings.get<bool>(skipWhileUsingKey) ?? true;

  /// Every app by default. Picks saved before the filter existed keep
  /// meaning "only these" until [migrate] looks at them.
  AppFilter get appFilter {
    if (AppFilters.fromStoredName(_settings.get<String>(appFilterKey))
        case final stored?) {
      return stored;
    }

    return switch (_stored(allowedAppsKey)) {
      null => .APP_FILTER_ALL,
      _ => .APP_FILTER_ONLY,
    };
  }

  /// The apps picked for "only these apps".
  Set<String> get allowedApps => _stored(allowedAppsKey) ?? const {};

  /// The apps muted for "all apps except".
  Set<String> get excludedApps => _stored(excludedAppsKey) ?? const {};

  bool isAllowed(String packageName) => switch (appFilter) {
    .APP_FILTER_ALL_EXCEPT => !excludedApps.contains(packageName),
    .APP_FILTER_ONLY => allowedApps.contains(packageName),
    _ => true,
  };

  Future<void> setEnabled(bool value) => _settings.set(enabledKey, value);

  Future<void> setSkipWhileUsing(bool value) =>
      _settings.set(skipWhileUsingKey, value);

  Future<void> setAppFilter(AppFilter filter) =>
      _settings.set(appFilterKey, filter.storedName);

  /// Turns each app in [choices] on or off in the active filter's list.
  /// Turning an app off while every app comes through mutes just that app.
  Future<void> setAllowed(Map<String, bool> choices) async {
    if (choices.isEmpty) {
      return;
    }

    final filter = appFilter;
    final turnsOneOff = choices.containsValue(false);
    if (filter == .APP_FILTER_ALL && !turnsOneOff) {
      return;
    }

    if (filter == .APP_FILTER_ONLY) {
      await _setList(allowedAppsKey, allowedApps, choices, keepWhen: true);
      return;
    }

    if (filter == .APP_FILTER_ALL) {
      await setAppFilter(.APP_FILTER_ALL_EXCEPT);
    }

    await _setList(excludedAppsKey, excludedApps, choices, keepWhen: false);
  }

  /// Apps were picked before filters existed and [migrate] hasn't run.
  bool get needsMigration =>
      _settings.get<String>(appFilterKey) == null &&
      _stored(allowedAppsKey) != null;

  /// Gives a filter to picks saved before filters existed. Turning
  /// mirroring on used to save the installed messaging apps on its own, so
  /// those untouched picks become "all apps"; a list with another app added
  /// or a messaging app removed was chosen by hand and stays "only these
  /// apps".
  Future<void> migrate(Set<String> installedMessagingApps) async {
    final picked = _stored(allowedAppsKey);
    if (!needsMigration || picked == null) {
      return;
    }

    final wasDefault =
        MessagingApps.packages.containsAll(picked) &&
        picked.containsAll(installedMessagingApps);
    await setAppFilter(switch (wasDefault) {
      true => .APP_FILTER_ALL,
      false => .APP_FILTER_ONLY,
    });
  }

  /// Whether [key] is one of the settings above.
  static bool owns(String key) => const {
    enabledKey,
    skipWhileUsingKey,
    appFilterKey,
    allowedAppsKey,
    excludedAppsKey,
  }.contains(key);

  Set<String>? _stored(String key) => switch (_settings.get<List<Object?>>(
    key,
  )) {
    final List<Object?> stored => stored.whereType<String>().toSet(),
    null => null,
  };

  Future<void> _setList(
    String key,
    Set<String> current,
    Map<String, bool> choices, {
    required bool keepWhen,
  }) async {
    final next = {...current};
    for (final MapEntry(key: packageName, value: allowed) in choices.entries) {
      if (allowed == keepWhen) {
        next.add(packageName);
        continue;
      }

      next.remove(packageName);
    }

    await _settings.set(key, next.toList()..sort());
  }
}
