import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/ui.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The whole app: theme, localizations, navigation and the home page.
class FerretApp extends StatelessWidget {
  const FerretApp({
    super.key,
    required this.host,
    required this.pause,
    required this.features,
    required this.featureContext,
    this.menubar,
  });

  final EngineHost host;

  /// Shared with the Android service notification, so a pause from either
  /// place shows in both.
  final PauseController pause;
  final List<FeatureUi> features;
  final FeatureContext featureContext;

  /// The macOS menubar, for files dragged over its popover and icon.
  final FerretMenubar? menubar;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: host),
        ChangeNotifierProvider.value(value: pause),
      ],
      child: ShellScope(
        features: features,
        featureContext: featureContext,
        child: WidgetsApp(
          navigatorKey: featureContext.navigatorKey,
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
          home: const StartPage(),
          builder: (context, child) => _Themed(
            navigatorKey: featureContext.navigatorKey,
            menubar: menubar,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
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
          child: FileDropZone(
            menubar: menubar,
            child: PairingPromptListener(
              navigatorKey: navigatorKey,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
