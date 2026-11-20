import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:flutter/widgets.dart';
import 'package:power/l10n/l10n.dart';
import 'package:power/models/models.dart';
import 'package:power/ui/widgets/widgets.dart';
import 'package:power/view_models/power_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Shizuku, step by step: install, start, allow. Only the step to do next
/// shows its button; the rest are ticked or greyed.
class PowerShizukuFrame extends StatelessWidget {
  const PowerShizukuFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final shizuku = context.select<PowerViewModel, ShizukuStatus>(
      (viewModel) => viewModel.status.shizuku,
    );
    final usesShizuku = context.select<PowerViewModel, bool>(
      (viewModel) => viewModel.usesShizuku,
    );
    final batteryUnrestricted = context.select<PowerViewModel, bool>(
      (viewModel) => viewModel.status.batteryUnrestricted,
    );
    final isBusy = context.select<PowerViewModel, bool>(
      (viewModel) => viewModel.isBusy,
    );
    final notice = context.select<PowerViewModel, PowerNotice?>(
      (viewModel) => viewModel.notice,
    );
    final viewModel = context.read<PowerViewModel>();
    final l10n = context.powerL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final current = switch (shizuku) {
      .notInstalled => 0,
      .notRunning => 1,
      .notAuthorized => 2,
      .ready => switch (usesShizuku) {
        true => 3,
        false => 2,
      },
    };
    final showsNotice =
        notice == .shizukuRefused ||
        notice == .shizukuNotOpened ||
        notice == .linkFailed;

    return GroupedCard(
      children: [
        GroupedCell(
          child: Text(
            l10n.shizukuIntro,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        ),
        SetupStepRow(
          title: l10n.stepInstallTitle,
          body: l10n.stepInstallBody,
          state: _stateOf(0, current),
          buttonLabel: l10n.stepInstallButton,
          enabled: !isBusy,
          onPressed: viewModel.getShizuku,
        ),
        SetupStepRow(
          title: l10n.stepStartTitle,
          body: l10n.stepStartBody,
          state: _stateOf(1, current),
          buttonLabel: l10n.stepStartButton,
          enabled: !isBusy,
          onPressed: viewModel.openShizuku,
        ),
        SetupStepRow(
          title: l10n.stepAllowTitle,
          body: l10n.stepAllowBody,
          state: _stateOf(2, current),
          buttonLabel: l10n.stepAllowButton,
          enabled: !isBusy,
          onPressed: viewModel.allowShizuku,
        ),
        if (notice != null && showsNotice)
          GroupedCell(
            child: NoticeText(l10n.noticeText(notice), tone: .danger),
          ),
        if (usesShizuku) ...[
          GroupedCell(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                NoticeText(l10n.shizukuOn, tone: .success),
                Spacing.v4,
                NoticeText(l10n.shizukuOnBody),
              ],
            ),
          ),
          GroupedRow(
            title: l10n.batteryTitle,
            subtitle: switch (batteryUnrestricted) {
              true => l10n.batteryOn,
              false => l10n.batteryBody,
            },
            trailing: switch (batteryUnrestricted) {
              true => null,
              false => GhostButton(
                mainAxisSize: .min,
                label: l10n.turnOn,
                enable: !isBusy,
                onPressed: viewModel.allowBackgroundRunning,
              ),
            },
          ),
          GroupedCell(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GhostButton(
                mainAxisSize: .min,
                label: l10n.stopUsingShizuku,
                enable: !isBusy,
                onPressed: viewModel.stopUsingShizuku,
              ),
            ),
          ),
        ],
      ],
    );
  }

  SetupStepState _stateOf(int step, int current) {
    if (step < current) {
      return .done;
    }

    if (step == current) {
      return .current;
    }

    return .later;
  }
}
