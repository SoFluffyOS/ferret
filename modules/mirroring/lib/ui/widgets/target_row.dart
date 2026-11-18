import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A screen that can be shown: its device's name, how it is connected,
/// and the button that shows it.
class TargetRow extends StatelessWidget {
  const TargetRow({
    super.key,
    required this.name,
    required this.line,
    required this.actionLabel,
    required this.onAction,
  });

  final String name;
  final String line;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  name,
                  overflow: .ellipsis,
                  style: typography.base1.copyWith(color: palette.text),
                ),
                Text(
                  line,
                  overflow: .ellipsis,
                  style: typography.caption1.copyWith(
                    color: palette.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Spacing.h12,
          Button(variant: .ghost, label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
