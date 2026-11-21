import 'package:feature_kit/layout/layout.dart';
import 'package:feature_kit/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A place to drop on, such as a device's card, while a drag is over it:
/// the shelf box's look. The place tints in the accent colour with an
/// accent ring on its own corner, what it shows fades back, and one short
/// [label] in the middle says what a drop does. Where the place can't take
/// it ([refused]), all of it is muted and [label] says why. Nothing moves:
/// the overlay is drawn over [child] at its size.
class DropOverlay extends StatelessWidget {
  const DropOverlay({
    super.key,
    required this.radius,
    required this.child,
    this.label,
    this.icon,
    this.refused = false,
    this.compact = false,
  });

  /// The corner of the shape it covers, so the ring follows it.
  final double radius;
  final Widget child;

  /// Shown while it is set: what a drop here does, or why it can't.
  final String? label;
  final IconData? icon;

  /// The place can't take what is dragged over it.
  final bool refused;

  /// A line too short for a chip, such as a row of a list: [label] sits
  /// on the tint itself.
  final bool compact;

  /// How much of what a card shows stays under the overlay. A line keeps
  /// none: its label sits where the line's own text is.
  static const double _behind = 0.12;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    final palette = context.palette;
    final color = switch (refused) {
      true => palette.mutedText,
      false => palette.link,
    };
    final base = Color.alphaBlend(
      switch (refused) {
        true => palette.mutedText.withValues(alpha: 0.10),
        false => palette.accent.withValues(alpha: 0.14),
      },
      palette.surface,
    );
    final style = context.fluffyTheme.typography.caption1.copyWith(
      color: color,
      fontWeight: .w600,
    );
    final line = switch (label) {
      final label? => Row(
        mainAxisSize: .min,
        children: [
          if (icon case final icon?) ...[
            Icon(icon, size: Spacing.d16, color: color),
            Spacing.h8,
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: .ellipsis,
              style: style,
            ),
          ),
        ],
      ),
      null => null,
    };

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: switch (line) {
                final line? => Semantics(
                  key: ValueKey(label),
                  liveRegion: true,
                  label: label,
                  child: ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: switch (compact) {
                          true => base,
                          false => base.withValues(alpha: 1 - _behind),
                        },
                        shape: Corners.shape(
                          radius,
                          side: BorderSide(
                            color: switch (refused) {
                              true => palette.mutedText.withValues(alpha: 0.4),
                              false => palette.accent,
                            },
                            width: Spacing.d2,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Spacing.d12,
                          ),
                          child: switch (compact) {
                            true => line,
                            false => _Chip(child: line),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                null => const SizedBox.shrink(),
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The label in a capsule of the page's colour, as on the shelf box: in
/// the middle of the place it is far from every corner, so it takes the
/// shape of a lone label, not one concentric with the place.
class _Chip extends StatelessWidget {
  const _Chip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: context.palette.background,
      shape: Corners.shape(Corners.capsule),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d12,
        vertical: Spacing.d6,
      ),
      child: child,
    ),
  );
}
