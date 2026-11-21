import 'package:flutter/widgets.dart';

/// A colour that stands for one place in the app, such as a row of
/// Settings: you learn the place by its colour. The same in light and
/// dark, and each carries a white icon at 3:1 or better.
enum PlaceColor {
  blue(Color(0xFF007AFF)),
  teal(Color(0xFF008299)),
  green(Color(0xFF248A3D)),
  orange(Color(0xFFC96A00)),
  pink(Color(0xFFD8315B)),
  purple(Color(0xFF8944AB)),
  indigo(Color(0xFF5856D6)),
  cyan(Color(0xFF0071A4)),
  brown(Color(0xFF96785A)),
  grey(Color(0xFF6C6C70));

  const PlaceColor(this.fill);

  final Color fill;

  /// What is drawn on [fill].
  static const Color onFill = Color(0xFFFFFFFF);
}
