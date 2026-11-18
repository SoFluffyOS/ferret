import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/ui/widgets/widgets.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Messages in a computer's Settings: notices and saved texts.
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

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          ToggleRow(
            title: l10n.notifySetting,
            detail: l10n.notifyDetail,
            value: notify,
            onChanged: viewModel.setNotify,
          ),
          Spacing.v16,
          Text(
            l10n.forgetDetail,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
          Spacing.v8,
          Align(
            alignment: .centerLeft,
            child: Button(
              variant: .secondary,
              label: l10n.forgetHistory,
              enable: hasSaved,
              onPressed: viewModel.forgetSavedTexts,
            ),
          ),
        ],
      ),
    );
  }
}
