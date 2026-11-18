import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/ui.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The app in one view, with its own navigator. Every view shows the same
/// running app: the providers and the [ShellScope] sit above them all.
class AppView extends StatelessWidget {
  const AppView({super.key, required this.navigatorKey, this.menubar});

  final GlobalKey<NavigatorState> navigatorKey;
  final FerretMenubar? menubar;

  @override
  Widget build(BuildContext context) {
    final features = ShellScope.of(context).features;

    return WidgetsApp(
      navigatorKey: navigatorKey,
      title: 'Ferret',
      color: const Color(0xFFE8833A),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        ShellLocalizations.delegate,
        for (final feature in features) ...feature.localizationsDelegates,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: ShellLocalizations.supportedLocales,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: const HomePage(),
      builder: (context, child) => _Themed(
        navigatorKey: navigatorKey,
        menubar: menubar,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

const _ferretBlue = Color(0xFF0A66D6);

class _Themed extends StatelessWidget {
  const _Themed({
    required this.navigatorKey,
    required this.menubar,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final FerretMenubar? menubar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final fallback = FluffyThemeData.fallback(brightness: brightness);
    // A deeper blue than the default, so primary buttons get white labels
    // at more than 4.5:1 contrast.
    final theme = fallback.copyWith(
      platform: defaultTargetPlatform,
      colors: fallback.colors.copyWith(primary: _ferretBlue),
    );

    return FluffyTheme(
      data: theme,
      child: Builder(
        builder: (context) => DefaultTextStyle(
          style: theme.typography.base1.copyWith(color: context.palette.text),
          child: ScreenSizeScope(
            child: FileDropZone(
              menubar: menubar,
              child: PairingPromptListener(
                navigatorKey: navigatorKey,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
