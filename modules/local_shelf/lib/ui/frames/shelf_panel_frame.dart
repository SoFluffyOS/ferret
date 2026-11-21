import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/ui/frames/shelf_box_frame.dart';
import 'package:local_shelf/ui/widgets/shelf_corners.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The shelf in the floating panel that a drag brings over other apps:
/// the same panel as in the popover, header inside, filling the window.
/// The window takes the popover's corner, so the box sits in it at the
/// same gap on every side and the same corner.
class ShelfPanelFrame extends StatelessWidget {
  const ShelfPanelFrame({
    super.key,
    required this.onOpenList,
    required this.onHover,
  });

  final VoidCallback onOpenList;

  /// The pointer came onto the panel (true) or left it.
  final ValueChanged<bool> onHover;

  /// Between the panel's edge and the box.
  static double get inset => ShelfCorners.boxInset;

  static double get radius => Corners.floatingPanel;

  /// Room for the box with its header and one row of tiles, [inset] from
  /// every edge.
  static Size get size => Size(Spacing.d16 * 20, Spacing.d4 * 35);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: ColoredBox(
        color: context.palette.background,
        child: ShelfBoxFrame(
          onOpenList: onOpenList,
          expands: true,
          padding: EdgeInsets.all(inset),
        ),
      ),
    );
  }
}
