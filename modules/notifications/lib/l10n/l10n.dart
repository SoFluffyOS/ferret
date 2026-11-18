import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/generated/notifications_localizations.dart';
import 'package:protocol/notifications.dart';

export 'package:notifications/l10n/generated/notifications_localizations.dart';

extension NotificationsL10n on BuildContext {
  NotificationsLocalizations get notificationsL10n =>
      NotificationsLocalizations.of(this);
}

extension AppsSummary on NotificationsLocalizations {
  /// Which apps a phone mirrors, such as "All apps" or "All apps except 2".
  /// [count] is how many apps the filter names.
  String appsSummary(AppFilter filter, int count) => switch (filter) {
    .APP_FILTER_ALL_EXCEPT => appsAllExcept(count),
    .APP_FILTER_ONLY => appsOnly(count),
    _ => appsAll,
  };
}

/// The strings in the system language, for notices shown outside any
/// widget, falling back to English.
NotificationsLocalizations platformNotificationsL10n() {
  final locale = PlatformDispatcher.instance.locale;
  final supported = NotificationsLocalizations.supportedLocales.any(
    (candidate) => candidate.languageCode == locale.languageCode,
  );
  if (!supported) {
    return lookupNotificationsLocalizations(const Locale('en'));
  }

  return lookupNotificationsLocalizations(locale);
}
