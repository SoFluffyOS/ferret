import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Messages in a computer's Settings: notices and saved texts, which can be
/// forgotten after a confirmation.
class ComputerSettingsFrame extends StatelessWidget {
  const ComputerSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final notify = context.select<ComputerSettingsViewModel, bool>(
      (viewModel) => viewModel.notify,
    );
    final hasSaved = context.select<ComputerSettingsViewModel, bool>(
      (viewModel) => viewModel.hasSavedTexts,
    );
    final viewModel = context.read<ComputerSettingsViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;

    return GroupedCard(
      children: [
        SettingSwitchRow(
          title: l10n.notifySetting,
          body: l10n.notifyDetail,
          value: notify,
          onChanged: viewModel.setNotify,
        ),
        GroupedCell(
          child: Column(
            crossAxisAlignment: .stretch,
            mainAxisSize: .min,
            children: [
              Text(
                l10n.forgetDetail(ThisComputer.here),
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
              if (hasSaved) ...[
                Spacing.v8,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Button(
                    mainAxisSize: .min,
                    variant: .ghost,
                    color: palette.danger,
                    label: l10n.forgetHistory,
                    onPressed: () =>
                        unawaited(_confirmForget(context, viewModel)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmForget(
    BuildContext context,
    ComputerSettingsViewModel viewModel,
  ) async {
    final l10n = context.messagesL10n;
    final answer = await ConfirmDialog.show(
      context,
      title: l10n.forgetConfirmTitle,
      message: l10n.forgetConfirmBody(ThisComputer.here),
      negativeText: l10n.cancel,
      positiveText: l10n.forgetConfirm,
    );
    if (answer != .positive) {
      return;
    }

    await viewModel.forgetSavedTexts();
  }
}
