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

  /// The Mac menubar popover's own corner. macOS draws that window
  /// (NSPopover), not Ferret: since macOS 26 its glass is a continuous
  /// 20-point curve around the content, so anything at its edge is
  /// concentric with 20.
  static double get popover => Spacing.d20;

  /// A desktop window's own corner, which the system draws round
  /// Ferret's window and its feature windows. On a Mac it is a continuous
  /// 16-point curve since macOS 26, with or without a toolbar; Windows 11
  /// rounds windows by 8 and GNOME by 12. A shape at the window's edge is
  /// concentric with it: a selected list line 8 in from the side is 8.
  static double get window => switch (defaultTargetPlatform) {
    .windows => Spacing.d8,
    .linux => Spacing.d12,
    _ => Spacing.d16,
  };

  /// The windows Ferret draws itself next to the popover, such as the
  /// shelf panel a drag brings over other apps: the popover's corner, so
  /// the two read as one family and the same box fits both.
  static double get floatingPanel => popover;

  /// A dialog's corner: its buttons' corner plus the dialog's inset, so a
  /// button at the dialog's bottom corner shares its centre. On a phone or
  /// a tablet that is Material 3's dialog corner (Extra large, 28 dp =
  /// 12 + 16). On a computer see [dialogInset].
  static double get dialog => around(control, dialogInset);

  /// How far a dialog's buttons sit from its sides and its bottom; see
  /// [dialog]. 16 on a phone or a tablet, and on a Mac, where an alert
  /// keeps its buttons 16 from the edges with a 26-point corner since
  /// macOS 26 (28 here, so the buttons' 12 nests exactly). Windows 11
  /// (8 px dialogs, 4 px buttons) and GNOME (18 px alerts, 12 px buttons)
  /// round less, so there the dialog is 24, at 12.
  static double get dialogInset => switch (defaultTargetPlatform) {
    .windows || .linux => Spacing.d12,
    _ => Spacing.d16,
  };

  /// Shapes inside the popover or the floating panel never go under this,
  /// like a concentric shape's minimum on Apple's platforms.
  static double get windowMinimum => Spacing.d4;

  /// [inner] with a floor: where the concentric radius would be smaller
  /// than [minimum], the shape keeps [minimum].
  static double concentric(double outer, double inset, {double? minimum}) =>
      math.max(inner(outer, inset), minimum ?? windowMinimum);

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
