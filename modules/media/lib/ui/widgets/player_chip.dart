import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One player to pick when several are playing, such as "Spotify on Pixel".
class PlayerChip extends StatelessWidget {
  const PlayerChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fill = switch (selected) {
      true => palette.accent,
      false => palette.background,
    };
    final textColor = switch (selected) {
      true => palette.background,
      false => palette.text,
    };

    return Tappable(
      onTap: onTap,
      child: DecoratedBox(
        // A chip in a card takes a control's corner.
        decoration: ShapeDecoration(
          color: fill,
          shape: Corners.shape(Corners.control),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.d10,
            vertical: Spacing.d4,
          ),
          child: Text(
            label,
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: textColor,
            ),
            overflow: .ellipsis,
          ),
        ),
      ),
    );
  }
}
