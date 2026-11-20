import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card on the phone, only while mirroring is on but notification
/// access is off. Turning mirroring on is offered in "Do more".
class PhoneHomeFrame extends StatelessWidget {
  const PhoneHomeFrame({super.key, required this.onSetUp});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final stage = context.select<MirrorSetupViewModel, SetupStage>(
      (viewModel) => viewModel.stage,
    );
    final checked = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.checked,
    );
    if (stage != .needsAccess || !checked) {
      return const SizedBox.shrink();
    }

    final l10n = context.notificationsL10n;

    return FeatureCard(
      icon: LucideIcons.bell,
      title: l10n.title,
      onTap: onSetUp,
      actions: [
        Button(
          mainAxisSize: .min,
          variant: .primary,
          label: l10n.fix,
          onPressed: onSetUp,
        ),
      ],
      children: [
        StatusLine(
          text: l10n.phoneHomePaused(ThisComputer.handheld),
          tone: .warning,
        ),
      ],
    );
  }
}
