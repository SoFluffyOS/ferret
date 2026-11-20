import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// This computer as strings name it. Pass [here] as a string's `here` and
/// write it as `{here, select, macOS{this Mac} windows{this PC}
/// other{this computer}}`.
abstract final class ThisComputer {
  static String get here => defaultTargetPlatform.name;

  /// What a phone's own strings call this device: `tablet` on an Android
  /// tablet or an iPad, else `phone`. Pass it as a string's `here` and
  /// write it as `{here, select, tablet{this tablet} other{this phone}}`.
  static String get handheld => switch (isTabletScreen) {
    true => 'tablet',
    false => 'phone',
  };

  /// A screen whose shorter side is at least this many points is a
  /// tablet's, as Android itself counts.
  static const tabletSide = 600.0;

  /// Whether this device's screen is a tablet's. Measured on the whole
  /// display, not the window: in split screen a tablet's window can be
  /// narrower than a phone's, and it is still a tablet.
  static bool get isTabletScreen {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) {
      return false;
    }

    final display = views.first.display;
    final side = display.size.shortestSide / display.devicePixelRatio;
    return side >= tabletSide;
  }
}
