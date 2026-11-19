import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One big place to drop files: a device, or all of them. Filled, never
/// outlined; the one under the pointer fills with the accent.
class DropTargetTile extends StatelessWidget {
  const DropTargetTile({
    super.key,
    required this.icon,
    required this.name,
    this.label = '',
    this.highlighted = false,
    this.dimmed = false,
    this.compact = false,
    this.onTap,
  });

  final IconData icon;
  final String name;
  final String label;
  final bool highlighted;

  /// Offline: shown, so it doesn't look like it vanished, but faded.
  final bool dimmed;

  /// One row instead of a stacked icon and name, for "All my devices".
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final isDark = context.fluffyTheme.isDark;
    // On dark, 12 % of the accent barely shows and accent text is too dim,
    // so the fill is stronger and the name and icon stay light.
    final fill = switch ((highlighted, isDark)) {
      (true, false) => palette.accent.withValues(alpha: 0.12),
      (true, true) => palette.accent.withValues(alpha: 0.32),
      (false, _) => palette.surface,
    };
    final nameColor = switch ((highlighted, isDark)) {
      (true, false) => palette.accent,
      _ => palette.text,
    };
    final opacity = switch (dimmed) {
      true => 0.45,
      false => 1.0,
    };
    final nameText = Text(
      name,
      style: typography.base1.copyWith(
        color: nameColor,
        fontWeight: .w600,
      ),
      overflow: .ellipsis,
      maxLines: 1,
    );
    final labelText = Text(
      label,
      style: typography.caption1.copyWith(color: palette.mutedText),
      overflow: .ellipsis,
      maxLines: 1,
    );
    final content = switch (compact) {
      true => Row(
        children: [
          Icon(icon, size: Spacing.d20, color: nameColor),
          Spacing.h12,
          Expanded(child: nameText),
          if (label.isNotEmpty) labelText,
        ],
      ),
      false => Column(
        mainAxisAlignment: .center,
        children: [
          Icon(icon, size: Spacing.d32, color: nameColor),
          Spacing.v8,
          nameText,
          if (label.isNotEmpty) ...[Spacing.vertical(Spacing.d2), labelText],
        ],
      ),
    };
    final tile = Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: fill,
          shape: Corners.shape(Corners.card),
        ),
        child: Padding(
          padding: EdgeInsets.all(Spacing.d16),
          child: content,
        ),
      ),
    );

    // Tappable sizes to its child, so the tile is told to fill first.
    final filled = switch (compact) {
      true => SizedBox(width: double.infinity, child: tile),
      false => SizedBox.expand(child: tile),
    };
    if (onTap == null) {
      return filled;
    }

    return Tappable(onTap: onTap, child: filled);
  }
}
