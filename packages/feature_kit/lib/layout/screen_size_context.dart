import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

extension ScreenSizeContext on BuildContext {
  /// The breakpoint of the view this widget is drawn in. Rebuilds the
  /// widget only when the breakpoint changes, not on every resize. Outside
  /// a `ScreenSizeScope` it follows the view's width directly.
  ScreenSize get screenSize =>
      select<ScreenSizeNotifier?, ScreenSize?>(
        (notifier) => notifier?.screenSize,
      ) ??
      ScreenSize.of(this);
}
