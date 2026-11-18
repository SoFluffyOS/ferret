import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app_view.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/ui.dart';

/// The whole app: theme, localizations, navigation and the home page.
///
/// With [views] it draws every view Ferret has (the popover and the desktop
/// window on a Mac) and must be given to `runWidget`. Without, it draws the
/// one view it is put in.
class FerretApp extends StatelessWidget {
  const FerretApp({
    super.key,
    required this.host,
    required this.pause,
    required this.features,
    required this.featureContext,
    this.menubar,
    this.views,
    this.navigation,
    this.featureWindows,
  });

  final EngineHost host;

  /// Shared with the Android service notification, so a pause from either
  /// place shows in both.
  final PauseController pause;
  final List<FeatureUi> features;
  final FeatureContext featureContext;

  /// The macOS menubar, for files dragged over its popover and icon.
  final FerretMenubar? menubar;

  final AppViews? views;

  /// Every view's navigation, when something outside the app (the menubar)
  /// needs to go places too. Without, the app keeps its own.
  final WindowNavRegistry? navigation;

  /// The window a feature opens for itself, drawn next to [views].
  final FeatureWindowHost? featureWindows;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: host),
        ChangeNotifierProvider.value(value: pause),
        if (views case final views?) ChangeNotifierProvider.value(value: views),
        if (menubar case final menubar?) Provider.value(value: menubar),
        if (featureWindows case final featureWindows?)
          ChangeNotifierProvider.value(value: featureWindows),
        Provider<WindowNavRegistry>(
          create: (_) => navigation ?? WindowNavRegistry(featureContext),
          lazy: false,
        ),
      ],
      child: ShellScope(
        features: features,
        featureContext: featureContext,
        child: switch (views) {
          null => AppView(
            navigatorKey: featureContext.navigatorKey,
            menubar: menubar,
          ),
          final views => AppViewsFrame(
            views: views,
            builder: (navigatorKey) =>
                AppView(navigatorKey: navigatorKey, menubar: menubar),
          ),
        },
      ),
    );
  }
}
