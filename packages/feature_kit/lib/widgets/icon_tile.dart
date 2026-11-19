import 'package:feature_kit/layout/corners.dart';
import 'package:feature_kit/theme/place_color.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A small coloured tile with a white icon, at the start of a row that
/// opens a place.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color});

  final IconData icon;
  final PlaceColor color;

  static double get size => Spacing.d28;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color.fill,
        shape: Corners.shape(Corners.tile),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, size: Spacing.d16, color: PlaceColor.onFill),
      ),
    );
  }
}
