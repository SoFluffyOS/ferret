import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Where one step of a checklist stands.
enum StepState { done, now, later }

/// One step of a checklist that ticks itself: a mark, what to do, and
/// the how-to underneath while it is the step to do now.
class SetupStepRow extends StatelessWidget {
  const SetupStepRow({
    super.key,
    required this.title,
    required this.state,
    this.children = const [],
  });

  final String title;
  final StepState state;

  /// The how-to, shown only while this is the step to do.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final (icon, color) = switch (state) {
      .done => (LucideIcons.circleCheck, palette.success),
      .now => (LucideIcons.circleDot, palette.accent),
      .later => (LucideIcons.circle, palette.mutedText),
    };
    final titleColor = switch (state) {
      .later => palette.mutedText,
      _ => palette.text,
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: Spacing.d2),
            child: Icon(icon, size: Spacing.d16, color: color),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  style: typography.base1.copyWith(color: titleColor),
                ),
                if (state == .now && children.isNotEmpty) ...[
                  Spacing.v4,
                  ...children,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
