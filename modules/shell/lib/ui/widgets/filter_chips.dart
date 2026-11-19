import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A row of capsules to narrow a list down, one of them picked, such as
/// "All", "Pixel 7", "iPhone" over Activity. Wraps onto a second line when
/// they don't fit.
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;

  /// The index of the picked one.
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d8),
      child: Wrap(
        spacing: Spacing.d8,
        runSpacing: Spacing.d8,
        children: [
          for (final (index, label) in labels.indexed)
            Semantics(
              selected: index == selected,
              button: true,
              child: Tappable(
                onTap: () => onSelected(index),
                hoverOverlayBorderRadius: Spacing.d16,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: switch (index == selected) {
                      true => palette.accent.withValues(alpha: 0.18),
                      false => palette.surface,
                    },
                    shape: const StadiumBorder(),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Spacing.d12,
                      vertical: Spacing.d6,
                    ),
                    child: Text(
                      label,
                      style: typography.caption1.copyWith(
                        color: switch (index == selected) {
                          true => palette.link,
                          false => palette.text,
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
