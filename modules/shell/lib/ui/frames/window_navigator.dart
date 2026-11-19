import 'package:flutter/widgets.dart';

/// A navigator around the whole window, above the pane's own. Dialogs go
/// to the outermost navigator, so they cover the device list too instead of
/// sitting inside the pane.
class WindowNavigator extends StatelessWidget {
  const WindowNavigator({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _WindowContent(
      content: child,
      child: Navigator(
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, _, _) => _WindowContent.of(context),
        ),
      ),
    );
  }
}

/// Hands the window's content to the one route of [WindowNavigator], which
/// is built once and would otherwise keep the first content it saw.
class _WindowContent extends InheritedWidget {
  const _WindowContent({required this.content, required super.child});

  final Widget content;

  static Widget of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WindowContent>()?.content ??
      const SizedBox.shrink();

  @override
  bool updateShouldNotify(_WindowContent oldWidget) =>
      content != oldWidget.content;
}
