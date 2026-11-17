import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/feature/notifications_feature.dart';
import 'package:notifications/l10n/l10n.dart';

/// The app side of Notifications.
class NotificationsFeatureUi extends FeatureUi {
  NotificationsFeatureUi() : feature = NotificationsFeature();

  @override
  final NotificationsFeature feature;

  @override
  String get featureId => NotificationsFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    NotificationsLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.notificationsL10n.title;

  @override
  IconData get icon => LucideIcons.bell;
}
