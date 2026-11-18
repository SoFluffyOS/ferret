import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Wraps [child] in the theme and localizations the shell's widgets expect.
Widget testApp(Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  localizationsDelegates: const [
    ShellLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: ShellLocalizations.supportedLocales,
  builder: (context, _) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: DefaultTextStyle(style: const TextStyle(), child: child),
  ),
);
