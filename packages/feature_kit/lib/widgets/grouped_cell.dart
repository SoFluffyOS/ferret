import 'package:feature_kit/layout/layout.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Anything that isn't a row, inside a `GroupedCard`: a note, a line of
/// buttons, a field. It gets the rows' inset, so its content starts where
/// their text does.
class GroupedCell extends StatelessWidget {
  const GroupedCell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PageInsets.row,
        vertical: Spacing.d12,
      ),
      child: child,
    );
  }
}
