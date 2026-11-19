import 'dart:ui';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';

/// The language picked in Settings → Advanced, kept in settings and
/// applied through [AppLocale].
abstract final class LanguagePreference {
  /// Settings key: a language tag such as `vi`; missing follows the system.
  static const key = 'shell.language';

  /// Each language Ferret has strings for, by its own name, so a person who
  /// can't read the current language still finds theirs.
  static const endonyms = {'en': 'English', 'vi': 'Tiếng Việt'};

  /// Applies the stored choice. Call once at start, before the first frame.
  static void load(SettingsStore settings) {
    AppLocale.chosen.value = AppLocale.parse(settings.get<String>(key));
  }

  /// Shows Ferret in [locale] from now on; null follows the system again.
  static Future<void> choose(SettingsStore settings, Locale? locale) async {
    AppLocale.chosen.value = locale;
    await settings.set(key, locale?.toLanguageTag());
  }

  /// The name of [locale] in its own language, or its tag when unknown.
  static String endonymOf(Locale locale) =>
      endonyms[locale.languageCode] ?? locale.toLanguageTag();
}
