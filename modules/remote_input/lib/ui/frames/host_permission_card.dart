import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class HostPermissionCard extends StatelessWidget {
  const HostPermissionCard({super.key, required this.ask});

  final PermissionAsk ask;

  @override
  Widget build(BuildContext context) {
    final l10n = context.remoteInputL10n;
    final viewModel = context.read<HostViewModel>();

    return FeatureCard(
      icon: LucideIcons.shieldAlert,
      iconTone: .danger,
      title: l10n.permissionTitle(ask.deviceName),
      subtitle: l10n.permissionBody(ask.deviceName),
      trailing: HostDismissButton(
        label: l10n.dismiss,
        onTap: viewModel.dismissPermissionAsk,
      ),
      actions: [
        Button(
          mainAxisSize: .min,
          variant: .primary,
          label: l10n.openSettings,
          onPressed: () => unawaited(viewModel.requestAccess()),
        ),
      ],
    );
  }
}
