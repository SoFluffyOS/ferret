import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One key on the touchpad page: an icon or a short label. [selected] marks
/// an armed modifier.
class KeyChip extends StatelessWidget {
  const KeyChip({
    super.key,
    required this.tooltip,
    required this.onTap,
    this.icon,
    this.label,
    this.selected = false,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData? icon;
  final String? label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final (background, foreground) = switch (selected) {
      true => (palette.accent, palette.background),
      false => (palette.surface, palette.text),
    };

    return Tappable(
      tooltip: tooltip,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Spacing.d8),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.d12,
            vertical: Spacing.d8,
          ),
          child: switch ((icon, label)) {
            (final icon?, _) => Icon(
              icon,
              size: Spacing.d18,
              color: foreground,
            ),
            (_, final label?) => Text(
              label,
              style: typography.body2.copyWith(color: foreground),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}
