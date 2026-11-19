import 'dart:ui';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:shell/l10n/l10n.dart';

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
    AppLocale.supported = ShellLocalizations.supportedLocales;
    AppLocale.chosen.value = AppLocale.parse(settings.get<String>(key));
  }

  /// Shows Ferret in [locale] from now on; null follows the system again.
  /// Android hears it too, so its notices match. Going back to the system
  /// only clears Android's per-app language when Ferret set it, never one
  /// picked in Android's own settings.
  static Future<void> choose(
    SettingsStore settings,
    Locale? locale, {
    FerretSystem? system,
  }) async {
    final hadChoice = settings.get<String>(key) != null;
    AppLocale.chosen.value = locale;
    await settings.set(key, locale?.toLanguageTag());
    if (locale == null && !hadChoice) {
      return;
    }

    await (system ?? FerretSystem()).setAppLanguage(locale?.toLanguageTag());
  }

  /// The name of [locale] in its own language, or its tag when unknown.
  static String endonymOf(Locale locale) =>
      endonyms[locale.languageCode] ?? locale.toLanguageTag();
}
