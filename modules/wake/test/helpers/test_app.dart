import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:wake/l10n/l10n.dart';

/// Wraps [child] in the theme, strings and navigator the wake widgets
/// expect.
Widget testApp(
  Widget child, {
  GlobalKey<NavigatorState>? navigatorKey,
  bool scroll = true,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  navigatorKey: navigatorKey,
  localizationsDelegates: const [
    WakeLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: WakeLocalizations.supportedLocales,
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  builder: (context, navigator) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: DefaultTextStyle(
      style: const TextStyle(),
      child: navigator ?? const SizedBox.shrink(),
    ),
  ),
  home: switch (scroll) {
    true => SingleChildScrollView(child: child),
    false => child,
  },
);
