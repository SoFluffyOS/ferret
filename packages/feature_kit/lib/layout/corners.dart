import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Ferret's corners: the design system's continuous curve, in a few fixed
/// sizes, and concentric where one shape sits inside another.
abstract final class Corners {
  /// Small tiles, such as the icon of a Settings row.
  static double get tile => Spacing.d6;

  /// A highlighted line in a list or a menu.
  static double get row => Spacing.d8;

  /// Cards and grouped rows: what the design system's own card uses.
  static double get card => Spacing.d12;

  /// Panels that float over a pane, such as the drop sheet or a QR frame.
  static double get panel => Spacing.d16;

  /// Under this a curve next to a bigger one looks like a mistake.
  static const double _smallest = 4;

  /// The radius of a shape that sits [inset] inside a corner of [outer].
  /// The two curves then share a centre, so the gap between them is even
  /// all the way round. Where that leaves almost nothing the shape is
  /// square: give a control there a capsule instead.
  static double inner(double outer, double inset) {
    final radius = outer - inset;
    if (radius < _smallest) {
      return 0;
    }

    return radius;
  }

  static BorderRadius radius(double radius) =>
      BorderRadius.all(Radius.circular(radius));

  /// A filled or outlined shape with continuous corners of [radius].
  static RoundedSuperellipseBorder shape(
    double radius, {
    BorderSide side = BorderSide.none,
  }) => RoundedSuperellipseBorder(
    borderRadius: Corners.radius(radius),
    side: side,
  );

  /// Half the height of anything a control can be: buttons, badges and
  /// progress bars are capsules.
  static double get capsule => Spacing.d200;
}
