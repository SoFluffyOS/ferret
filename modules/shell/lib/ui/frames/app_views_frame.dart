import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/services/services.dart';

/// Draws the app once per view Ferret has: the main one, and the desktop
/// window while it is open. Goes to `runWidget`, above any view.
class AppViewsFrame extends StatelessWidget {
  const AppViewsFrame({super.key, required this.views, required this.builder});

  final AppViews views;

  /// The app for one view, around the navigator that view owns.
  final Widget Function(GlobalKey<NavigatorState> navigatorKey) builder;

  @override
  Widget build(BuildContext context) {
    final window = context.select<AppViews, FlutterView?>(
      (views) => views.window,
    );

    return ViewCollection(
      views: [
        View(
          key: ValueKey(views.main.viewId),
          view: views.main,
          child: builder(views.mainNavigatorKey),
        ),
        if (window != null)
          View(
            key: ValueKey(window.viewId),
            view: window,
            child: builder(views.windowNavigatorKey),
          ),
      ],
    );
  }
}
