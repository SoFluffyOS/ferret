import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// A line that opens nothing by itself still takes the keyboard, and
/// shows it has it the way a tappable line does.
class ActivityFocusableLine extends StatefulWidget {
  const ActivityFocusableLine({
    super.key,
    required this.focusNode,
    required this.child,
  });

  final FocusNode focusNode;
  final Widget child;

  @override
  State<ActivityFocusableLine> createState() => _ActivityFocusableLineState();
}

class _ActivityFocusableLineState extends State<ActivityFocusableLine> {
  bool _showsFocus = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onShowFocusHighlight: (shows) => setState(() => _showsFocus = shows),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: switch (_showsFocus) {
            true => context.palette.surface,
            false => null,
          },
          shape: Corners.shape(Corners.row),
        ),
        child: widget.child,
      ),
    );
  }
}
