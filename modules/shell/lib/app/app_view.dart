import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app_localizations.dart';
import 'package:shell/app/ferret_theme.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/ui.dart';
import 'package:shell/view_models/view_models.dart';

/// The app in one view, with its own navigator and its own place in the
/// app. Every view shows the same running app: the providers and the
/// [ShellScope] sit above them all.
class AppView extends StatefulWidget {
  const AppView({super.key, required this.navigatorKey, this.menubar});

  final GlobalKey<NavigatorState> navigatorKey;
  final FerretMenubar? menubar;

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  late final WindowNavViewModel _nav;
  late final WindowNavRegistry _registry;

  @override
  void initState() {
    super.initState();
    _nav = WindowNavViewModel(
      host: context.read<EngineHost>(),
      navigatorKey: widget.navigatorKey,
      settings: ShellScope.read(context).featureContext.engine.settings,
      pageFor: (destination) => DestinationPage(destination: destination),
    );
    _registry = context.read<WindowNavRegistry>()..add(_nav);
  }

  @override
  void dispose() {
    _registry.remove(_nav);
    _nav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features = ShellScope.of(context).features;

    return WidgetsApp(
      navigatorKey: widget.navigatorKey,
      title: 'Ferret',
      color: const Color(0xFFE8833A),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: appLocalizationsDelegates(features),
      supportedLocales: ShellLocalizations.supportedLocales,
      locale: chosenLocale(context),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: const WindowHomePage(),
      builder: (context, child) => ChangeNotifierProvider.value(
        value: _nav,
        child: _Themed(
          navigatorKey: widget.navigatorKey,
          menubar: widget.menubar,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _Themed extends StatelessWidget {
  const _Themed({
    required this.navigatorKey,
    required this.menubar,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final FerretMenubar? menubar;
  final Widget child;

  /// The desktop window has a title bar to keep up to date; the popover and
  /// a phone's screen have none.
  void Function(String title)? _windowTitle(BuildContext context) {
    final menubar = this.menubar;
    final isMainView =
        View.of(context).viewId ==
        WidgetsBinding.instance.platformDispatcher.implicitView?.viewId;
    if (menubar == null || isMainView) {
      return null;
    }

    return (title) => unawaited(menubar.setWindowTitle(title));
  }

  /// Only the menubar popover: the window has a menu bar with these keys.
  Widget _popoverKeys(BuildContext context, Widget child) {
    final menubar = this.menubar;
    final isMainView =
        View.of(context).viewId ==
        WidgetsBinding.instance.platformDispatcher.implicitView?.viewId;
    if (menubar == null || !isMainView) {
      return child;
    }

    return PopoverKeysFrame(
      navigatorKey: navigatorKey,
      onClose: () => unawaited(menubar.hide()),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onTitle = _windowTitle(context);

    return FerretTheme(
      child: ScreenSizeScope(
        child: FileDropZone(
          menubar: menubar,
          child: PairingPromptListener(
            navigatorKey: navigatorKey,
            child: _UnderTitleBar(
              isWindow: onTitle != null,
              child: WindowShellFrame(
                onTitle: onTitle,
                child: _popoverKeys(context, child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Mac window draws under its see-through title bar. Its height counts
/// as the view's top padding, so every `SafeArea` keeps clear of the
/// traffic lights and the band stays free to move the window.
class _UnderTitleBar extends StatelessWidget {
  const _UnderTitleBar({required this.isWindow, required this.child});

  final bool isWindow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isWindow) {
      return child;
    }

    final data = MediaQuery.of(context);
    final padding = data.padding.copyWith(
      top: WindowLayout.macTitleBarHeight,
    );

    return MediaQuery(
      data: data.copyWith(
        padding: padding,
        viewPadding: data.viewPadding.copyWith(
          top: WindowLayout.macTitleBarHeight,
        ),
      ),
      child: child,
    );
  }
}
