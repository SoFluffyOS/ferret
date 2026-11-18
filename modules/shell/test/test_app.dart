import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Hosts [child] as the home route, with the theme and localizations the
/// shell's widgets expect, like the real app.
Widget testApp(Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  localizationsDelegates: const [
    ShellLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: ShellLocalizations.supportedLocales,
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  home: child,
  builder: (context, navigator) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: DefaultTextStyle(
      style: const TextStyle(),
      child: navigator ?? const SizedBox.shrink(),
    ),
  ),
);
