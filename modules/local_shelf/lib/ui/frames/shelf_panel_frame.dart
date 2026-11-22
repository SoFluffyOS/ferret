import 'dart:math' as math;

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/ui/frames/shelf_box_frame.dart';
import 'package:local_shelf/ui/widgets/shelf_corners.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The shelf in the floating panel that a drag brings over other apps:
/// the same panel as in the popover, header inside, filling the window.
/// The window takes the popover's corner, so the box sits in it at the
/// same gap on every side and the same corner. Only a Mac shows it, for a
/// drag the mouse makes, so it is sized for a mouse whatever the
/// platform's density says.
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

  /// [size], taller by what larger text adds to the header's line and the
  /// tiles' two label lines, on the 4-point grid.
  static Size sizeFor(TextScaler scaler) {
    final lines = [
      (fontSize: 12.0, height: 1.25),
      (fontSize: 11.0, height: 1.2),
      (fontSize: 11.0, height: 1.2),
    ];
    var grows = 0.0;
    for (final line in lines) {
      grows += (scaler.scale(line.fontSize) - line.fontSize) * line.height;
    }

    final grid = Spacing.d4;
    final base = size;
    return Size(
      base.width,
      base.height + (math.max(0, grows) / grid).ceil() * grid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FluffyDensityScope(
      density: .pointer,
      child: MouseRegion(
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
      ),
    );
  }
}
