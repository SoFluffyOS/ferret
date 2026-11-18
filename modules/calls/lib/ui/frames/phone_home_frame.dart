import 'package:calls/l10n/l10n.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card on the phone, only while calls are on but the Phone
/// permission is missing. Turning calls on is offered in "Do more".
class PhoneHomeFrame extends StatelessWidget {
  const PhoneHomeFrame({super.key, required this.onSetUp});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final stage = context.select<PhoneSetupViewModel, CallsSetupStage>(
      (viewModel) => viewModel.stage,
    );
    final checked = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.checked,
    );
    if (stage != .needsPermission || !checked) {
      return const SizedBox.shrink();
    }

    final l10n = context.callsL10n;

    return FeatureCard(
      icon: LucideIcons.phone,
      title: l10n.title,
      onTap: onSetUp,
      children: [StatusLine(text: l10n.phoneHomePaused, tone: .warning)],
      actions: [
        Button(
          mainAxisSize: .min,
          variant: .ghost,
          label: l10n.fix,
          onPressed: onSetUp,
        ),
      ],
    );
  }
}
