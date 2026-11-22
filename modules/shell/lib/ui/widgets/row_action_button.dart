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
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The one real next step on the screen; every other one is outlined.
  final bool isPrimary;

  /// What a screen reader says instead of [label].
  final String? semanticLabel;

  /// The whole sentence a short [label] stands for, shown on hover and
  /// said by screen readers when [semanticLabel] is left out.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    // Focused from the keyboard, the outline gives way to the focus ring,
    // so the button doesn't wear two. A finger's 48 dp reaches into the
    // card's inset instead of growing the line.
    return OutsetTouchTarget(
      child: GhostFill(
        applies: !isPrimary,
        child: ButtonFocusRing(
          builder: (context, keyboardFocused) => Button(
            variant: switch (isPrimary) {
              true => .primary,
              false => .ghost,
            },
            borderWidth: switch (keyboardFocused) {
              true => 0,
              false => null,
            },
            onPressed: onPressed,
            enable: onPressed != null,
            semanticLabel: semanticLabel ?? tooltip,
            tooltip: tooltip,
            mainAxisSize: .min,
            // It sits a card's inset from the card's corner, so its curve shares
            // the card's centre.
            radius: Corners.control,
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.d12,
              vertical: Spacing.d6,
            ),
            child: Text(
              label,
              semanticsLabel: switch (semanticLabel ?? tooltip) {
                null => null,
                _ => '',
              },
              maxLines: 1,
              overflow: .ellipsis,
              style: context.fluffyTheme.typography.caption1,
            ),
          ),
        ),
      ),
    );
  }
}
