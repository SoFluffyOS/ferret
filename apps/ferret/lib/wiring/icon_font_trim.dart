import 'package:flutter/widgets.dart';

/// lucide_icons_flutter also brings six weighted variable fonts, about
/// 3 MB together, that Ferret never draws (it uses the plain `Lucide`).
/// Flutter's icon tree shaking leaves a font nobody names whole, but cuts
/// a named one down to the glyphs named, so naming one glyph of each
/// shrinks them to a few kilobytes in a release build.
abstract final class IconFontTrim {
  /// The X of each weight. Kept for the build to find, never drawn.
  @pragma('vm:entry-point')
  static const glyphs = [
    IconData(_x, fontFamily: 'Lucide100', fontPackage: _package),
    IconData(_x, fontFamily: 'Lucide200', fontPackage: _package),
    IconData(_x, fontFamily: 'Lucide300', fontPackage: _package),
    IconData(_x, fontFamily: 'Lucide400', fontPackage: _package),
    IconData(_x, fontFamily: 'Lucide500', fontPackage: _package),
    IconData(_x, fontFamily: 'Lucide600', fontPackage: _package),
  ];

  static const _x = 57778;
  static const _package = 'lucide_icons_flutter';
}
