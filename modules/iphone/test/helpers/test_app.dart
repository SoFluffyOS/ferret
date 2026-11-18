import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Wraps [child] in the theme and strings the iPhone widgets expect.
Widget testApp(Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  localizationsDelegates: const [
    IphoneLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: IphoneLocalizations.supportedLocales,
  builder: (context, _) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: DefaultTextStyle(
      style: const TextStyle(),
      child: SingleChildScrollView(child: child),
    ),
  ),
);
