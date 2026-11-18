import 'package:calls/l10n/l10n.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card on the phone: an invitation to set calls up, or a fix when
/// the permission is missing. Once calls work it shows nothing.
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
    final l10n = context.callsL10n;

    if (stage == .ready || (stage == .needsPermission && !checked)) {
      return const SizedBox.shrink();
    }

    final isOff = stage == .off;

    return FeatureCard(
      icon: LucideIcons.phone,
      title: l10n.title,
      subtitle: switch (isOff) {
        true => l10n.explainer,
        false => null,
      },
      onTap: onSetUp,
      children: [
        if (!isOff) StatusLine(text: l10n.phoneHomePaused, tone: .warning),
      ],
      actions: [
        Button(
          variant: .secondary,
          label: switch (isOff) {
            true => l10n.setUp,
            false => l10n.fix,
          },
          onPressed: onSetUp,
        ),
      ],
    );
  }
}
