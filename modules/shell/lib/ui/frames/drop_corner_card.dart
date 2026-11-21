import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/frames/drop_sending_status.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// How sending goes, in a window: a card in the pane's corner over the
/// page that stays. It sits in the window's corner, so its corner follows
/// the window's at the same gap from the side and the bottom, and what is
/// in it sits as far in from every edge.
class DropCornerCard extends StatelessWidget {
  const DropCornerCard({super.key, required this.phase});

  final DropPhase phase;

  /// Between the window's edges and the card.
  static double get inset => Spacing.d4;

  /// Between the card's edges and what is in it.
  static double get padding => Spacing.d12;

  static double get radius => Corners.concentric(Corners.window, inset);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: PaneWidths.narrowContent),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              // In dark mode a shadow doesn't show on the black pane, so the
              // fill lifts the card, as a dialog's does.
              color: switch (context.isDark) {
                true => palette.surface,
                false => palette.background,
              },
              shape: Corners.shape(radius),
              shadows: [
                BoxShadow(
                  color: palette.text.withValues(alpha: 0.16),
                  blurRadius: Spacing.d24,
                  offset: .new(0, Spacing.d4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: DropSendingStatus(phase: phase, isFlat: true),
            ),
          ),
        ),
      ),
    );
  }
}
