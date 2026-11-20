import 'package:calls/l10n/l10n.dart';
import 'package:calls/ui/frames/open_settings_failed.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class PhoneSetupReady extends StatelessWidget {
  const PhoneSetupReady({super.key});

  @override
  Widget build(BuildContext context) {
    final abilities = context
        .select<PhoneSetupViewModel, (bool, bool, bool, bool)>(
          (viewModel) => (
            viewModel.canSeeNumbers,
            viewModel.canSeeContacts,
            viewModel.canAnswer,
            viewModel.canDial,
          ),
        );
    final hasMissing = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.hasMissing,
    );
    final needsSettings = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.needsSettings,
    );
    final viewModel = context.read<PhoneSetupViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;
    final (canSeeNumbers, canSeeContacts, canAnswer, canDial) = abilities;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          StatusLine(text: l10n.ready, tone: .good),
          Spacing.v8,
          PhoneAbilityLine(text: l10n.capNumbers, allowed: canSeeNumbers),
          PhoneAbilityLine(text: l10n.capContacts, allowed: canSeeContacts),
          PhoneAbilityLine(text: l10n.capAnswer, allowed: canAnswer),
          PhoneAbilityLine(text: l10n.capDial, allowed: canDial),
          Spacing.v8,
          Text(
            l10n.audioOnPhone,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
          const OpenSettingsFailed(),
          if (hasMissing) ...[
            Spacing.v12,
            GhostButton(
              label: switch (needsSettings) {
                true => l10n.openSettings,
                false => l10n.allowRest,
              },
              onPressed: viewModel.allow,
            ),
          ],
          Spacing.v8,
          GhostButton(
            label: l10n.turnOff,
            onPressed: viewModel.turnOff,
          ),
        ],
      ),
    );
  }
}
