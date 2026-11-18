import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';

/// The route every Ferret page opens in. On iOS it slides in, and a swipe
/// from the left edge goes back, as in every iPhone app. Elsewhere the page
/// shows at once: a menubar popover or a phone with its own back button
/// gains nothing from a slide.
Route<T> ferretRoute<T>(Widget page) => switch (defaultTargetPlatform) {
  .iOS => CupertinoPageRoute<T>(builder: (_) => page),
  _ => PageRouteBuilder<T>(pageBuilder: (_, _, _) => page),
};
