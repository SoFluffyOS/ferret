import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:flutter/widgets.dart';
import 'package:power/l10n/l10n.dart';
import 'package:power/models/models.dart';
import 'package:power/ui/widgets/widgets.dart';
import 'package:power/view_models/power_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The ladder: every tier, whether this phone is on it, and what it adds.
class PowerLadderFrame extends StatelessWidget {
  const PowerLadderFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<PowerViewModel, PowerStatus>(
      (viewModel) => viewModel.status,
    );
    final tier = context.select<PowerViewModel, PowerTier>(
      (viewModel) => viewModel.tier,
    );
    final isBusy = context.select<PowerViewModel, bool>(
      (viewModel) => viewModel.isBusy,
    );
    final notice = context.select<PowerViewModel, PowerNotice?>(
      (viewModel) => viewModel.notice,
    );
    final viewModel = context.read<PowerViewModel>();
    final l10n = context.powerL10n;
    final showsNotice = notice == .grantFailed || notice == .settingsNotOpened;

    return GroupedCard(
      children: [
        for (final rung in LadderRung.values)
          LadderRungTile(
            key: ValueKey(rung),
            title: l10n.rungTitle(rung),
            stateLabel: switch (viewModel.isOn(rung)) {
              true => l10n.rungOn,
              false => l10n.rungOff,
            },
            isOn: viewModel.isOn(rung),
            perks: [
              for (final perk in LadderPerk.of(rung)) l10n.perkLabel(perk),
            ],
            children: switch (rung) {
              .notifications when !status.notificationAccess => [
                if (tier == .standard) ...[
                  Spacing.v8,
                  NoticeText(l10n.notificationsRestricted),
                ],
                Spacing.v8,
                Wrap(
                  spacing: Spacing.d8,
                  runSpacing: Spacing.d8,
                  children: [
                    Button(
                      mainAxisSize: .min,
                      variant: .ghost,
                      label: switch (tier) {
                        .standard => l10n.notificationsOpenSettings,
                        _ => l10n.notificationsTurnOnNow,
                      },
                      enable: !isBusy,
                      onPressed: viewModel.turnOnNotificationAccess,
                    ),
                    if (tier == .standard)
                      Button(
                        mainAxisSize: .min,
                        variant: .ghost,
                        label: l10n.appInfo,
                        enable: !isBusy,
                        onPressed: viewModel.openAppInfo,
                      ),
                  ],
                ),
              ],
              .messagesAndCalls when !status.messagesAndCalls => [
                Spacing.v8,
                NoticeText(l10n.messagesHint),
                Spacing.v8,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Button(
                    mainAxisSize: .min,
                    variant: .ghost,
                    label: l10n.appInfo,
                    enable: !isBusy,
                    onPressed: viewModel.openAppInfo,
                  ),
                ),
              ],
              _ => const [],
            },
          ),
        if (notice != null && showsNotice)
          GroupedCell(
            child: NoticeText(l10n.noticeText(notice), tone: .danger),
          ),
      ],
    );
  }
}
