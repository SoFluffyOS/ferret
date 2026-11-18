import 'package:protocol/notifications.dart';

/// How an [AppFilter] is stored in settings and read from older phones.
extension AppFilters on AppFilter {
  /// The settings value, by name.
  String get storedName => switch (this) {
    .APP_FILTER_ALL_EXCEPT => 'all_except',
    .APP_FILTER_ONLY => 'only',
    _ => 'all',
  };

  static AppFilter? fromStoredName(String? name) => switch (name) {
    'all' => .APP_FILTER_ALL,
    'all_except' => .APP_FILTER_ALL_EXCEPT,
    'only' => .APP_FILTER_ONLY,
    _ => null,
  };
}

/// Reads a phone's [MirrorSettings] the same way the phone applies them.
extension MirrorSettingsApps on MirrorSettings {
  /// Phones from before the filter only ever mirrored their picked apps.
  AppFilter get effectiveFilter => switch (appFilter) {
    .APP_FILTER_UNSPECIFIED => .APP_FILTER_ONLY,
    final filter => filter,
  };

  /// Whether [package]'s notifications come through.
  bool forwards(String package) => switch (effectiveFilter) {
    .APP_FILTER_ALL_EXCEPT => !excludedPackages.contains(package),
    .APP_FILTER_ONLY => allowedPackages.contains(package),
    _ => true,
  };

  /// How many apps the filter names: muted ones or picked ones.
  int get namedAppCount => switch (effectiveFilter) {
    .APP_FILTER_ALL_EXCEPT => excludedPackages.length,
    .APP_FILTER_ONLY => allowedPackages.length,
    _ => 0,
  };

  /// These settings with [update] applied the way the phone applies it, to
  /// show a change before the phone confirms it.
  MirrorSettings withUpdate(UpdateMirrorSettings update) {
    final next = deepCopy();
    if (update.hasAppFilter()) {
      next.appFilter = update.appFilter;
    }

    if (update.hasSkipWhileUsing()) {
      next.skipWhileUsing = update.skipWhileUsing;
    }

    final choices = update.apps;
    if (choices.isEmpty) {
      return next;
    }

    final turnsOneOff = choices.any((choice) => !choice.allowed);
    final filter = next.effectiveFilter;
    if (filter == .APP_FILTER_ALL && !turnsOneOff) {
      return next;
    }

    if (filter == .APP_FILTER_ONLY) {
      next.appFilter = .APP_FILTER_ONLY;
      _apply(next.allowedPackages, choices, keepWhen: true);
      return next;
    }

    next.appFilter = .APP_FILTER_ALL_EXCEPT;
    _apply(next.excludedPackages, choices, keepWhen: false);
    return next;
  }

  static void _apply(
    List<String> packages,
    List<AppChoice> choices, {
    required bool keepWhen,
  }) {
    final next = {...packages};
    for (final choice in choices) {
      if (choice.allowed == keepWhen) {
        next.add(choice.package);
        continue;
      }

      next.remove(choice.package);
    }

    packages
      ..clear()
      ..addAll(next.toList()..sort());
  }
}
