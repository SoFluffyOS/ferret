import 'dart:ui';

import 'package:flutter/widgets.dart';

/// The language Ferret shows: the one picked in Settings → Advanced, or the
/// system's when nothing was picked.
///
/// Widgets get their strings from `Localizations`; notices, the tray and
/// health lines are built outside any widget and ask [pick] instead, so both
/// follow the same choice.
abstract final class AppLocale {
  /// The language picked in Settings, or null to follow the system.
  static final ValueNotifier<Locale?> chosen = ValueNotifier(null);

  /// The language wanted right now, before matching it to what a module
  /// has strings for.
  static Locale get wanted =>
      chosen.value ?? PlatformDispatcher.instance.locale;

  /// The first of [supported] in the [wanted] language, else the first one
  /// (English).
  static Locale pick(List<Locale> supported) {
    final language = wanted.languageCode;
    for (final locale in supported) {
      if (locale.languageCode == language) {
        return locale;
      }
    }

    return supported.first;
  }

  /// Parses a stored language tag such as `vi` or `pt-BR`; null or empty
  /// means "follow the system".
  static Locale? parse(String? tag) {
    if (tag == null || tag.isEmpty) {
      return null;
    }

    final parts = tag.split(RegExp('[-_]'));
    return Locale.fromSubtags(
      languageCode: parts.first,
      countryCode: switch (parts.length) {
        > 1 => parts[1],
        _ => null,
      },
    );
  }

  /// Delegates put ahead of every module's own, so a test can swap the
  /// strings (a pseudo-locale) without touching the app's wiring.
  static List<LocalizationsDelegate<Object?>> debugLeadingDelegates = const [];
}
