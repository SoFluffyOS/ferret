import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// On the phone: whether a computer that shows this screen can tap and
/// type here, and how to turn Ferret control on, explained first.
class ControlSettingsFrame extends StatelessWidget {
  const ControlSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final canBeControlled = context.select<ShareViewModel, bool>(
      (viewModel) => viewModel.canBeControlled,
    );
    final path = context.select<ShareViewModel, ControlPath>(
      (viewModel) => viewModel.controlPath,
    );
    final alwaysCount = context.select<ShareViewModel, int>(
      (viewModel) => viewModel.controlAlwaysCount,
    );
    final viewModel = context.read<ShareViewModel>();
    final l10n = context.mirroringL10n;
    final caption = context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.mutedText,
    );
    if (!canBeControlled) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsControlTitle),
        GroupedCard(
          children: [
            GroupedCell(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(switch (path) {
                    .powerUps => l10n.settingsControlPowerUps,
                    .service => l10n.settingsControlService,
                    .none => l10n.settingsControlOff,
                  }, style: caption),
                  if (path != .powerUps) ...[
                    Spacing.v8,
                    Button(
                      variant: switch (path) {
                        .none => .primary,
                        _ => .ghost,
                      },
                      mainAxisSize: .min,
                      label: switch (path) {
                        .none => l10n.settingsControlTurnOn,
                        _ => l10n.settingsControlOpen,
                      },
                      onPressed: () => unawaited(_turnOn(context, path)),
                    ),
                  ],
                ],
              ),
            ),
            if (alwaysCount > 0)
              GroupedCell(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      l10n.settingsControlAlwaysCount(alwaysCount),
                      style: caption,
                    ),
                    Spacing.v8,
                    Button(
                      variant: .ghost,
                      mainAxisSize: .min,
                      label: l10n.settingsControlAskAgain,
                      onPressed: () =>
                          unawaited(viewModel.forgetControlAlways()),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Says what the service does before Android's settings open, every
  /// time it is turned on from here.
  Future<void> _turnOn(BuildContext context, ControlPath path) async {
    final viewModel = context.read<ShareViewModel>();
    if (path != .none) {
      await viewModel.openControlSettings();
      return;
    }

    final l10n = context.mirroringL10n;
    final answer = await ConfirmDialog.show(
      context,
      title: l10n.controlDisclosureTitle,
      message:
          '${l10n.controlDisclosureBody}\n\n${l10n.controlDisclosureSteps}',
      negativeText: l10n.notNow,
      positiveText: l10n.controlDisclosureOpen,
      barrierLabel: l10n.dismiss,
    );
    if (answer != .positive) {
      return;
    }

    await viewModel.openControlSettings();
  }
}
