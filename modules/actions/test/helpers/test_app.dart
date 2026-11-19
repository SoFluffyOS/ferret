import 'package:actions/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Wraps [child] in the theme, strings and navigator the widgets expect.
Widget testApp(
  Widget child, {
  bool scroll = true,
  GlobalKey<NavigatorState>? navigatorKey,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  navigatorKey: navigatorKey,
  localizationsDelegates: const [
    ActionsLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: ActionsLocalizations.supportedLocales,
  builder: (context, navigator) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: DefaultTextStyle(
      style: const TextStyle(),
      child: navigator ?? const SizedBox.shrink(),
    ),
  ),
  onGenerateRoute: (_) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => switch (scroll) {
      true => SingleChildScrollView(child: child),
      false => child,
    },
  ),
);
