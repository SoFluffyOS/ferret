import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_updates/ferret_updates.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:updates/l10n/l10n.dart';
import 'package:updates/models/models.dart';
import 'package:updates/ui/update_activity.dart';
import 'package:updates/view_models/view_models.dart';

/// Updates in About: the switch that says what the check sends, betas,
/// and where things stand with Check now.
class UpdateAboutFrame extends StatelessWidget {
  const UpdateAboutFrame({super.key, required this.onWhatsNew});

  final VoidCallback onWhatsNew;

  @override
  Widget build(BuildContext context) {
    final checks = context.select<UpdatesViewModel, bool>(
      (viewModel) => viewModel.checks,
    );
    final betas = context.select<UpdatesViewModel, bool>(
      (viewModel) => viewModel.betas,
    );
    final phase = context.select<UpdatesViewModel, UpdatePhase>(
      (viewModel) => viewModel.phase,
    );
    final problem = context.select<UpdatesViewModel, UpdateProblem?>(
      (viewModel) => viewModel.problem,
    );
    final release = context.select<UpdatesViewModel, UpdateRelease?>(
      (viewModel) => viewModel.release,
    );
    final viewModel = context.read<UpdatesViewModel>();
    final l10n = context.updatesL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final current = viewModel.currentVersion;
    final status = switch (phase) {
      .checking => l10n.checking,
      .failed => UpdateActivity.problemText(l10n, problem),
      _ when release != null => switch (viewModel.kind.installsItself) {
        true => l10n.ready(release.versionText),
        false => l10n.readyOut(release.versionText),
      },
      .upToDate => l10n.upToDate(current),
      _ when !checks => l10n.statusOff(current),
      _ => l10n.youHave(current),
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.title),
        GroupedCard(
          children: [
            SettingSwitchRow(
              title: l10n.checkSwitch,
              body: l10n.checkSwitchBody,
              value: checks,
              onChanged: (value) => unawaited(viewModel.setChecks(value)),
            ),
            if (checks)
              SettingSwitchRow(
                title: l10n.betaSwitch,
                body: l10n.betaSwitchBody,
                value: betas,
                onChanged: (value) => unawaited(viewModel.setBetas(value)),
              ),
            GroupedCell(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      status,
                      style: typography.base2.copyWith(
                        color: switch (phase == .failed) {
                          true => palette.danger,
                          false => palette.mutedText,
                        },
                      ),
                    ),
                  ),
                  Spacing.h8,
                  if (release != null)
                    GhostButton(
                      mainAxisSize: .min,
                      label: l10n.whatsNew,
                      onPressed: onWhatsNew,
                    ),
                  if (release == null)
                    GhostButton(
                      mainAxisSize: .min,
                      label: l10n.checkNow,
                      tooltip: l10n.checkNowTooltip,
                      semanticLabel: l10n.checkNowTooltip,
                      enable: !phase.isBusy,
                      onPressed: () => unawaited(viewModel.check()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
