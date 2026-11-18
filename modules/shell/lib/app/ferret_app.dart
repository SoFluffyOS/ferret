import 'package:feature_kit/feature_kit.dart';
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
  });

  final EngineHost host;

  /// Shared with the Android service notification, so a pause from either
  /// place shows in both.
  final PauseController pause;
  final List<FeatureUi> features;
  final FeatureContext featureContext;

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
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _Themed extends StatelessWidget {
  const _Themed({required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final theme = FluffyThemeData.fallback(brightness: brightness)
        .copyWith(platform: defaultTargetPlatform);

    return FluffyTheme(
      data: theme,
      child: Builder(
        builder: (context) => DefaultTextStyle(
          style: theme.typography.body1.copyWith(color: context.palette.text),
          child: FileDropZone(
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
