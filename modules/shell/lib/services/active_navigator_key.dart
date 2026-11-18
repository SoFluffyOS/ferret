import 'package:flutter/widgets.dart';

/// Stands for the navigator of whichever view the person is looking at.
///
/// Features keep the app's navigator key from the moment the app starts and
/// ask it for a navigator when they have something to show. On a Mac the
/// popover and the desktop window each have a navigator, so this key is
/// never given to a widget: every lookup goes to the key [_active] names at
/// that moment.
class ActiveNavigatorKey extends GlobalKey<NavigatorState> {
  const ActiveNavigatorKey(this._active) : super.constructor();

  final GlobalKey<NavigatorState> Function() _active;

  @override
  BuildContext? get currentContext => _active().currentContext;

  @override
  Widget? get currentWidget => _active().currentWidget;

  @override
  NavigatorState? get currentState => _active().currentState;
}
