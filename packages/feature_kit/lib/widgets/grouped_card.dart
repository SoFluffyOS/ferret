import 'package:feature_kit/layout/layout.dart';
import 'package:feature_kit/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Rows that belong together, in one filled card: each row reaches the
/// card's edges, a hairline sets it apart from the next, and the first
/// and last rows follow the card's corners. Rows bring their own padding
/// (`GroupedRow`, `SettingSwitchRow`); wrap anything else in a
/// `GroupedCell`.
class GroupedCard extends StatelessWidget {
  const GroupedCard({
    super.key,
    required this.children,
    this.separatorIndent,
  });

  final List<Widget> children;

  /// Where the lines between rows start, from the card's leading edge:
  /// where the rows' text starts. Left out, that is [PageInsets.row];
  /// rows that start with an icon tile pass the tile's width more.
  final double? separatorIndent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final indent = separatorIndent ?? PageInsets.row;

    return ClipRSuperellipse(
      borderRadius: Corners.radius(Corners.card),
      child: ColoredBox(
        color: palette.surface,
        child: Column(
          crossAxisAlignment: .stretch,
          mainAxisSize: .min,
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0)
                FluffyDivider(
                  extent: Spacing.d1,
                  thickness: Spacing.d1,
                  indent: indent,
                  color: palette.separator,
                ),
              GroupedEdge(
                isFirst: index == 0,
                isLast: index == children.length - 1,
                child: child,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Whether a row of a `GroupedCard` touches the card's top or bottom edge,
/// where a control at its end sits in the card's corner.
class GroupedEdge extends InheritedWidget {
  const GroupedEdge({
    super.key,
    required this.isFirst,
    required this.isLast,
    required super.child,
  });

  final bool isFirst;
  final bool isLast;

  /// Null outside a `GroupedCard`.
  static GroupedEdge? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GroupedEdge>();

  @override
  bool updateShouldNotify(GroupedEdge oldWidget) =>
      isFirst != oldWidget.isFirst || isLast != oldWidget.isLast;
}
