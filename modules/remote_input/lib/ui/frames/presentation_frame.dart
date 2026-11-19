import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The presentation remote while in control: the time the talk has run,
/// a big Next, Back, and the black screen. It fills the height it gets.
class PresentationFrame extends StatelessWidget {
  const PresentationFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final elapsed = context.select<PresentationViewModel, Duration>(
      (viewModel) => viewModel.elapsed,
    );
    final isTiming = context.select<PresentationViewModel, bool>(
      (viewModel) => viewModel.isTiming,
    );
    final isBlack = context.select<PresentationViewModel, bool>(
      (viewModel) => viewModel.isBlack,
    );
    final viewModel = context.read<PresentationViewModel>();
    final l10n = context.remoteInputL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Center(
          child: Tappable(
            tooltip: l10n.presentRestartTimer,
            onTap: viewModel.restartTimer,
            child: Column(
              children: [
                Text(
                  _clock(elapsed),
                  style: typography.title1.copyWith(
                    color: palette.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  switch (isTiming) {
                    true => l10n.presentRestartTimer,
                    false => l10n.presentTimerHint,
                  },
                  style: typography.caption1.copyWith(color: palette.mutedText),
                ),
              ],
            ),
          ),
        ),
        Spacing.v16,
        Expanded(
          flex: 3,
          child: SlideButton(
            label: l10n.presentNext,
            icon: LucideIcons.chevronRight,
            isPrimary: true,
            onPressed: viewModel.next,
          ),
        ),
        Spacing.v12,
        Expanded(
          child: Row(
            crossAxisAlignment: .stretch,
            children: [
              Expanded(
                child: SlideButton(
                  label: l10n.presentPrevious,
                  icon: LucideIcons.chevronLeft,
                  onPressed: viewModel.previous,
                ),
              ),
              Spacing.h12,
              Expanded(
                child: SlideButton(
                  label: switch (isBlack) {
                    true => l10n.presentShowSlides,
                    false => l10n.presentBlackScreen,
                  },
                  icon: switch (isBlack) {
                    true => LucideIcons.monitor,
                    false => LucideIcons.monitorOff,
                  },
                  onPressed: viewModel.toggleBlack,
                ),
              ),
            ],
          ),
        ),
        Spacing.v12,
        Text(
          l10n.presentWorksWith,
          textAlign: .center,
          style: typography.caption1.copyWith(color: palette.mutedText),
        ),
      ],
    );
  }

  static String _clock(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }
}
