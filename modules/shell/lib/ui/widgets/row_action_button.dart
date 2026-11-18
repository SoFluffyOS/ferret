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
  });

  final String label;
  final VoidCallback? onPressed;

  /// The one real next step on the screen; every other one is outlined.
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: switch (isPrimary) {
        true => .primary,
        false => .ghost,
      },
      onPressed: onPressed,
      enable: onPressed != null,
      mainAxisSize: .min,
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d12,
        vertical: Spacing.d6,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: .ellipsis,
        style: context.fluffyTheme.typography.caption1,
      ),
    );
  }
}
