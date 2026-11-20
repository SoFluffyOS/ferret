import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';

/// What this device is called while it is a computer's display: "this
/// Mac" and the like on a computer, "this phone" or "this tablet" on
/// Android. For the `here` of the display strings.
abstract final class DisplayHere {
  static String get value {
    if (defaultTargetPlatform != .android) {
      return ThisComputer.here;
    }

    return switch (ThisComputer.isTabletScreen) {
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
