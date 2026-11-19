import 'package:flutter/widgets.dart';

/// Says that a toolbar above already names what is shown, as in a
/// window's content pane. A first page with that same title leaves its own
/// title out, so the name isn't there twice.
class PaneToolbarScope extends InheritedWidget {
  const PaneToolbarScope({
    super.key,
    required this.title,
    required super.child,
  });

  /// What the toolbar says.
  final String title;

  static String? titleOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaneToolbarScope>()?.title;

  @override
  bool updateShouldNotify(PaneToolbarScope oldWidget) =>
      title != oldWidget.title;
}
