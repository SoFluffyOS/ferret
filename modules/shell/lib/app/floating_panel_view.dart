import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app_localizations.dart';
import 'package:shell/app/ferret_theme.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/panel_drop_zone.dart';

/// What a feature draws in the floating panel, under the app's theme and
/// strings. Drops there go to the feature's own place to drop.
class FloatingPanelView extends StatelessWidget {
  const FloatingPanelView({
    super.key,
    required this.builder,
    required this.menubar,
  });

  final WidgetBuilder builder;
  final FerretMenubar menubar;

  @override
  Widget build(BuildContext context) {
    final features = ShellScope.of(context).features;

    return WidgetsApp(
      color: const Color(0xFFE8833A),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: appLocalizationsDelegates(features),
      supportedLocales: ShellLocalizations.supportedLocales,
      locale: chosenLocale(context),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: PanelDropZone(
        menubar: menubar,
        child: Builder(builder: builder),
      ),
      builder: (context, child) => FerretTheme(
        child: ScreenSizeScope(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
