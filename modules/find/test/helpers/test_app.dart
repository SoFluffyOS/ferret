import 'package:find/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Wraps [child] in the theme and strings the find widgets expect.
Widget testApp(Widget child, {bool scroll = true}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  localizationsDelegates: const [
    FindLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: FindLocalizations.supportedLocales,
  builder: (context, _) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: DefaultTextStyle(
      style: const TextStyle(),
      child: switch (scroll) {
        true => SingleChildScrollView(child: child),
        false => child,
      },
    ),
  ),
);
