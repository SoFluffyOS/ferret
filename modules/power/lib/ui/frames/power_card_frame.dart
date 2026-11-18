import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:power/l10n/l10n.dart';
import 'package:power/models/models.dart';
import 'package:power/view_models/power_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card. It is there only while a step can be taken: a power-up to
/// turn on, or one that stopped and needs a hand.
class PowerCardFrame extends StatelessWidget {
  const PowerCardFrame({super.key, required this.onOpen});

  /// Opens the Power-ups page.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final prompt = context.select<PowerViewModel, PowerPrompt?>(
      (viewModel) => viewModel.prompt,
    );
    final isBusy = context.select<PowerViewModel, bool>(
      (viewModel) => viewModel.isBusy,
    );
    final notice = context.select<PowerViewModel, PowerNotice?>(
      (viewModel) => viewModel.notice,
    );
    final viewModel = context.read<PowerViewModel>();
    final l10n = context.powerL10n;

    if (prompt == null) {
      return const SizedBox.shrink();
    }

    return FeatureCard(
      icon: LucideIcons.zap,
      title: l10n.title,
      subtitle: switch (notice) {
        final PowerNotice notice => l10n.noticeText(notice),
        null => l10n.promptText(prompt),
      },
      iconTone: switch (prompt.isProblem) {
        true => .warning,
        false => .accent,
      },
      subtitleTone: switch (notice) {
        null => .muted,
        _ => .danger,
      },
      onTap: onOpen,
      actions: [
        Button(
          variant: .primary,
          label: switch (prompt) {
            .startShizuku || .shizukuStopped => l10n.stepStartButton,
            .allowShizuku || .shizukuRevoked => l10n.stepAllowButton,
            .useRoot => l10n.cardSetUp,
            .rootLost => l10n.cardAskAgain,
          },
          enable: !isBusy,
          onPressed: switch (prompt) {
            .startShizuku || .shizukuStopped => viewModel.openShizuku,
            .allowShizuku || .shizukuRevoked => viewModel.allowShizuku,
            .useRoot => onOpen,
            .rootLost => viewModel.useRoot,
          },
        ),
        Button(
          variant: .ghost,
          label: switch (prompt) {
            .shizukuStopped || .shizukuRevoked => l10n.stopUsingShizuku,
            .rootLost => l10n.stopUsingRoot,
            _ => l10n.cardNotNow,
          },
          enable: !isBusy,
          onPressed: switch (prompt) {
            .shizukuStopped || .shizukuRevoked => viewModel.stopUsingShizuku,
            .rootLost => viewModel.stopUsingRoot,
            _ => viewModel.dismissCard,
          },
        ),
      ],
    );
  }
}
