import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Two blocks of a page: side by side where the page is [breakpoint] wide,
/// one under the other below that. It asks its own width, not the view's,
/// and both blocks keep their state when a resize moves them.
class TwoColumns extends StatefulWidget {
  const TwoColumns({
    super.key,
    required this.leading,
    required this.trailing,
    this.breakpoint = PaneWidths.twoColumns,
  });

  final List<Widget> leading;
  final List<Widget> trailing;
  final double breakpoint;

  @override
  State<TwoColumns> createState() => _TwoColumnsState();
}

class _TwoColumnsState extends State<TwoColumns> {
  final GlobalKey _leadingKey = GlobalKey();
  final GlobalKey _trailingKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final leading = Column(
      key: _leadingKey,
      crossAxisAlignment: .stretch,
      children: widget.leading,
    );
    final trailing = Column(
      key: _trailingKey,
      crossAxisAlignment: .stretch,
      children: widget.trailing,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < widget.breakpoint) {
          return Column(
            crossAxisAlignment: .stretch,
            children: [leading, trailing],
          );
        }

        return Row(
          crossAxisAlignment: .start,
          children: [
            Expanded(child: leading),
            Spacing.h24,
            Expanded(child: trailing),
          ],
        );
      },
    );
  }
}
