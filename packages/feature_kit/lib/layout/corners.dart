import 'dart:math' as math;

import 'package:feature_kit/layout/page_insets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Ferret's corners: the design system's continuous curve, in a few fixed
/// sizes, and concentric where one shape sits inside another.
abstract final class Corners {
  /// Small tiles, such as the icon of a Settings row.
  static double get tile => Spacing.d6;

  /// A highlighted line in a list or a menu.
  static double get row => Spacing.d8;

  /// Cards and grouped rows. On touch screens a card is a control's
  /// corner plus the card's inset, so a button at its corner shares the
  /// card's centre (24 = 12 + 12). Under a pointer rows are only 36 high:
  /// 24 would turn a one-row group into a pill, so a card stays at 16.
  static double get card => switch (defaultTargetPlatform) {
    .android || .iOS || .fuchsia => Spacing.d24,
    .macOS || .windows || .linux => Spacing.d16,
  };

  /// A button, chip or field inside a card: concentric with the card's
  /// corner at the card's inset, and never under 12, the design system's
  /// own button corner, so every control in a card has one shape. On
  /// touch screens that is exactly concentric; under a pointer the
  /// minimum wins and the gap at the corner opens by about 3 points.
  static double get control =>
      math.max(inner(card, PageInsets.row), _controlMinimum);

  static double get _controlMinimum => Spacing.d12;

  /// A big icon tile, such as the one at the top of a device's page.
  static double get iconTile => Spacing.d12;

  /// Panels that float over a pane, such as the drop sheet or a QR frame.
  static double get panel => Spacing.d16;

  /// Under this a curve next to a bigger one looks like a mistake.
  static const double _smallest = 4;

  /// The radius of a shape that sits [inset] inside a corner of [outer].
  /// The two curves then share a centre, so the gap between them is even
  /// all the way round. Where that leaves almost nothing the shape is
  /// square: [control] then falls back to a minimum, like a concentric
  /// shape with a minimum radius on Apple's platforms.
  static double inner(double outer, double inset) {
    final radius = outer - inset;
    if (radius < _smallest) {
      return 0;
    }

    return radius;
  }

  /// The radius of a shape that holds a shape of [inner] at [inset] from
  /// its corner, such as a floating bar around its buttons: the bar's
  /// corner follows the button's, not the other way round.
  static double around(double inner, double inset) => inner + inset;

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

  /// Half the height of anything a bar can be: badges and progress bars
  /// are capsules. Buttons in a card take [control].
  static double get capsule => Spacing.d200;
}
