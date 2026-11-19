import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A big button of the presentation remote, easy to hit without looking.
class SlideButton extends StatelessWidget {
  const SlideButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final (fill, ink) = switch (isPrimary) {
      true => (palette.accent, PlaceColor.onFill),
      false => (palette.surface, palette.text),
    };

    return Tappable(
      tooltip: label,
      onTap: onPressed,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: fill,
          shape: Corners.shape(Corners.card),
        ),
        child: Center(
          child: Column(
            mainAxisSize: .min,
            children: [
              Icon(icon, size: Spacing.d32, color: ink),
              Spacing.v8,
              Text(label, style: typography.body2.copyWith(color: ink)),
            ],
          ),
        ),
      ),
    );
  }
}
