import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// What this device is called while it is a computer's display: "this
/// Mac" and the like on a computer, "this phone" or "this tablet" on
/// Android. For the `here` of the display strings.
abstract final class DisplayHere {
  /// A screen whose shorter side is at least this many points is a
  /// tablet's, as Android itself counts.
  static const _tabletSide = 600.0;

  static String get value {
    if (defaultTargetPlatform != .android) {
      return ThisComputer.here;
    }

    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) {
      return 'android';
    }

    final view = views.first;
    final side = view.physicalSize.shortestSide / view.devicePixelRatio;
    return switch (side >= _tabletSide) {
      true => 'tablet',
      false => 'android',
    };
  }

  /// This device is worked with fingers, so a computer's display takes
  /// them as its mouse.
  static bool get isTouch => switch (defaultTargetPlatform) {
    .android || .iOS => true,
    _ => false,
  };
}
