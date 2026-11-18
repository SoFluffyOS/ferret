import 'package:calls/calls.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Wraps [child] in the theme, localizations and navigator the feature's
/// widgets expect, in a list as the shell does with cards and settings.
Widget testApp(Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  localizationsDelegates: const [
    CallsLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: CallsLocalizations.supportedLocales,
  builder: (context, _) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: DefaultTextStyle(
      style: const TextStyle(),
      child: Navigator(
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => ListView(children: [child]),
        ),
      ),
    ),
  ),
);
