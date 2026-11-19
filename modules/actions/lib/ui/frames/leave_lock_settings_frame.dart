import 'dart:async';

import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "Lock when your phone leaves" in Settings: a switch per Android phone,
/// how many minutes it must stay gone, and what keeps it from locking
/// someone out.
class LeaveLockSettingsFrame extends StatelessWidget {
  const LeaveLockSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final canLock = context.select<ActionsViewModel, bool>(
      (viewModel) => viewModel.canLockWhenGone,
    );
    if (!canLock) {
      return const SizedBox.shrink();
    }

    final phones = context
        .select<ActionsViewModel, List<({String id, String name, bool on})>>(
          (viewModel) => [
            for (final phone in viewModel.watchablePhones)
              (
                id: phone.id,
                name: phone.name,
                on: viewModel.locksWhenGone(phone.id),
              ),
          ],
        );
    final minutes = context.select<ActionsViewModel, int>(
      (viewModel) => viewModel.lockAfterMinutes,
    );
    final viewModel = context.read<ActionsViewModel>();
    final l10n = context.actionsL10n;
    final computer = ComputerKind.here.name;
    final note = context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.mutedText,
    );

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.leaveTitle),
        GroupedCard(
          children: [
            if (phones.isEmpty)
              GroupedCell(
                child: Text(l10n.leaveNoPhones(computer), style: note),
              ),
            for (final phone in phones)
              SettingSwitchRow(
                key: ValueKey('leave.${phone.id}'),
                title: l10n.leaveSwitch(phone.name, computer),
                body: l10n.leaveSwitchBody(phone.name, minutes),
                value: phone.on,
                onChanged: (value) => unawaited(
                  viewModel.setLocksWhenGone(phone.id, locks: value),
                ),
              ),
            if (phones.isNotEmpty) ...[
              GroupedRow(
                title: l10n.leaveAfter,
                trailing: MenuButton(
                  icon: LucideIcons.timer,
                  tooltip: l10n.leaveAfter,
                  label: l10n.leaveMinutes(minutes),
                  entries: [
                    for (
                      var choice = ActionsSettings.lockAfterMin;
                      choice <= ActionsSettings.lockAfterMax;
                      choice++
                    )
                      MenuEntry(
                        label: l10n.leaveMinutes(choice),
                        onSelected: () =>
                            unawaited(viewModel.setLockAfterMinutes(choice)),
                      ),
                  ],
                ),
              ),
              GroupedCell(child: Text(l10n.leaveNote, style: note)),
            ],
          ],
        ),
      ],
    );
  }
}
