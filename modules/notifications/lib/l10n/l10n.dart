import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/generated/notifications_localizations.dart';

export 'package:notifications/l10n/generated/notifications_localizations.dart';

extension NotificationsL10n on BuildContext {
  NotificationsLocalizations get notificationsL10n =>
      NotificationsLocalizations.of(this);
}
