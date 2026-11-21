import 'package:feature_kit/feature_kit.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The shelf's corners, concentric from the window down: the box sits at
/// the same gap from the window's sides and bottom, so its corner follows
/// the window's; a tile sits in the box's corner, and a thumbnail in the
/// tile's. Each level is the one around it less the gap between them.
abstract final class ShelfCorners {
  /// The popover's corner, and the floating panel's, which matches it.
  static double get window => Corners.popover;

  /// Between the window's left, right and bottom edges and the box.
  static double get boxInset => Spacing.d8;
  static double get box => Corners.concentric(window, boxInset);

  /// Between the box's edge and a tile.
  static double get tileInset => Spacing.d4;
  static double get tile => Corners.concentric(box, tileInset);

  /// Between a tile's edge and its thumbnail.
  static double get thumbInset => Spacing.d4;
  static double get thumb => Corners.concentric(tile, thumbInset);
}
