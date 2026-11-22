import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Wraps [child] in the theme, strings and navigator the widgets expect.
/// [density] stands in for the platform's, such as a computer's mouse for
/// what only computers show.
Widget testApp(
  Widget child, {
  bool scroll = true,
  GlobalKey<NavigatorState>? navigatorKey,
  FluffyDensity? density,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  navigatorKey: navigatorKey,
  localizationsDelegates: const [
    MirroringLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: MirroringLocalizations.supportedLocales,
  builder: (context, navigator) => FluffyTheme(
    data: FluffyThemeData.fallback(),
    child: DefaultTextStyle(
      style: const TextStyle(),
      child: switch (density) {
        final density? => FluffyDensityScope(
          density: density,
          child: navigator ?? const SizedBox.shrink(),
        ),
        null => navigator ?? const SizedBox.shrink(),
      },
    ),
  ),
  onGenerateRoute: (_) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => switch (scroll) {
      true => SingleChildScrollView(child: child),
      false => child,
    },
  ),
);
