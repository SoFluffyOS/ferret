import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/generated/notifications_localizations.dart';

export 'package:notifications/l10n/generated/notifications_localizations.dart';

extension NotificationsL10n on BuildContext {
  NotificationsLocalizations get notificationsL10n =>
      NotificationsLocalizations.of(this);
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
