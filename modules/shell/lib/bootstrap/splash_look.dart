import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Where and how big the system's launch screen draws the ferret, so the
/// first Flutter frame continues it without a jump. Lengths are in the
/// 1024-unit canvas of `branding/ferret-glyph.svg`.
@immutable
class SplashLook {
  const SplashLook({
    required this.anchor,
    required this.scale,
    this.clipRadius,
    this.bleed = false,
  });

  /// Android 12 and later: the adaptive foreground (108 dp, the plate's 824
  /// units on 72 dp) drawn at 288 dp and cut to a 192 dp circle, both
  /// centred on the screen. `launch_background.xml` draws the same on older
  /// Androids.
  static const android = SplashLook(
    anchor: Offset(512, 512),
    scale: 288 / 108 * _foregroundScale,
    clipRadius: 96 / (288 / 108 * _foregroundScale),
    bleed: true,
  );

  /// iOS: `LaunchImage` (the glyph's 460 × 711 box at 90 × 139 pt), centred
  /// by `LaunchScreen.storyboard`.
  static const iOS = SplashLook(anchor: Offset(512, 568.5), scale: 90 / 460);

  /// The look for this platform, or null where no splash comes first.
  static SplashLook? get current => switch (defaultTargetPlatform) {
    .android => android,
    .iOS => iOS,
    _ => null,
  };

  static const _foregroundScale = 72 / 824;

  /// The sable behind the ferret, the launch screens' background.
  static const background = Color(0xFF2B2320);

  /// The point of the canvas that sits at the middle of the screen.
  final Offset anchor;

  /// Logical pixels per canvas unit.
  final double scale;

  /// The circle, around [anchor], the system cuts the drawing to.
  final double? clipRadius;

  /// Whether the body runs on down, as on the launcher icon.
  final bool bleed;
}
