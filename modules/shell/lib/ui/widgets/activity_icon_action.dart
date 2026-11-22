import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class ActivityIconAction extends StatelessWidget {
  const ActivityIconAction({
    super.key,
    required this.action,
    required this.reachesUp,
    this.muted = false,
    this.subject,
  });

  /// What a 16-point glyph lacks to be a target as high as a [TextLink].
  static double get rise => Spacing.d8;
  final ActivityAction action;

  /// On the title's line the glyph sits at the bottom of its target, level
  /// with the title, and the target goes on above it. With text set large
  /// it is centred.
  final bool reachesUp;

  /// Drawn quieter, for the ✕ that only tidies up.
  final bool muted;

  /// The line's title, so a screen reader tells this line's ✕ from
  /// another's: "Dismiss: IMG_2041.jpg from Pixel 9".
  final String? subject;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      tooltip: action.label,
      semanticLabel: switch (subject) {
        final subject? => context.shellL10n.activityActionFor(
          action.label,
          subject,
        ),
        null => null,
      },
      onTap: action.onPressed,
      child: Padding(
        padding: switch (reachesUp) {
          true => EdgeInsets.only(
            left: Spacing.d6,
            right: Spacing.d6,
            top: ActivityIconAction.rise,
          ),
          false => EdgeInsets.symmetric(
            horizontal: Spacing.d6,
            vertical: ActivityIconAction.rise / 2,
          ),
        },
        child: Icon(
          action.icon,
          size: Spacing.d16,
          color: switch (muted) {
            true => context.palette.mutedText,
            false => context.palette.text,
          },
        ),
      ),
    );
  }
}
