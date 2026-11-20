import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Says that a section shares its page with others, as on a Settings
/// group's page. A section's own setup button is then a plain one: a page
/// has at most one filled button, and three "Turn on"s in a row would each
/// claim to be the one.
class SharedPageScope extends InheritedWidget {
  const SharedPageScope({super.key, required super.child});

  static bool isShared(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SharedPageScope>() != null;

  /// The variant of a section's main button: filled on its own page,
  /// plain on a shared one.
  static ButtonVariant mainButton(BuildContext context) =>
      switch (isShared(context)) {
        true => .ghost,
        false => .primary,
      };

  @override
  bool updateShouldNotify(SharedPageScope oldWidget) => false;
}
