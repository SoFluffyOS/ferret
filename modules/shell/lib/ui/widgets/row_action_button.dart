import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A button small enough to sit three in a row on a device or an activity
/// line, on a phone as on a computer.
class RowActionButton extends StatelessWidget {
  const RowActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The one real next step on the screen; every other one is outlined.
  final bool isPrimary;

  /// What a screen reader says instead of [label].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: switch (isPrimary) {
        true => .primary,
        false => .ghost,
      },
      onPressed: onPressed,
      enable: onPressed != null,
      semanticLabel: semanticLabel,
      mainAxisSize: .min,
      // It sits a card's padding from the card's corner, where a curve of
      // its own would be none at all: a capsule.
      radius: Corners.capsule,
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d12,
        vertical: Spacing.d6,
      ),
      child: Text(
        label,
        semanticsLabel: switch (semanticLabel) {
          null => null,
          _ => '',
        },
        maxLines: 1,
        overflow: .ellipsis,
        style: context.fluffyTheme.typography.caption1,
      ),
    );
  }
}
