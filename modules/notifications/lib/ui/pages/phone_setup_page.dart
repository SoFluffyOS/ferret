import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/feature/notifications_feature.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/services/services.dart';
import 'package:notifications/ui/frames/frames.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Mirroring setup on its own page, opened from the phone's home card.
class PhoneSetupPage extends StatelessWidget {
  const PhoneSetupPage({
    super.key,
    required this.feature,
    required this.access,
    required this.onChooseApps,
  });

  final NotificationsFeature feature;
  final NotificationAccess access;
  final VoidCallback onChooseApps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.notificationsL10n;

    return FerretPage(
      title: l10n.title,
      backLabel: l10n.back,
      children: [
        ChangeNotifierProvider(
          create: (_) => MirrorSetupViewModel(feature: feature, access: access),
          child: PhoneSetupFrame(onChooseApps: onChooseApps),
        ),
      ],
    );
  }
}
