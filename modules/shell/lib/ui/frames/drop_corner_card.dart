import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/frames/drop_sending_status.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// How sending goes, in a window: a card in the pane's corner over the
/// page that stays.
class DropCornerCard extends StatelessWidget {
  const DropCornerCard({super.key, required this.phase});

  final DropPhase phase;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: Padding(
        padding: EdgeInsets.all(Spacing.d16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: PaneWidths.narrowContent),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: palette.background,
              shape: Corners.shape(Corners.panel),
              shadows: [
                BoxShadow(
                  color: palette.text.withValues(alpha: 0.16),
                  blurRadius: Spacing.d24,
                  offset: .new(0, Spacing.d4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(Spacing.d16),
              child: DropSendingStatus(phase: phase),
            ),
          ),
        ),
      ),
    );
  }
}
