import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/ui/frames/shelf_box_frame.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The shelf in the floating panel that a drag brings over other apps:
/// the same box as in the popover, filling the panel, whose corner is
/// concentric with the box's.
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
  static double get inset => Spacing.d8;

  static double get radius => Corners.around(ShelfBoxFrame.radius, inset);

  /// Room for the header and one row of tiles.
  static Size get size => Size(Spacing.d16 * 20, Spacing.d8 * 19);

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
          padding: EdgeInsets.fromLTRB(inset, Spacing.d4, inset, inset),
        ),
      ),
    );
  }
}
