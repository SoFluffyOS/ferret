import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shell/app/ferret_theme.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';

/// What a feature draws in a window of its own, under the app's theme and
/// strings, with a navigator and a size of its own. It has no device list
/// and no pages of the app: the window is the feature's.
class FeatureWindowView extends StatelessWidget {
  const FeatureWindowView({super.key, required this.window});

  final FeatureWindow window;

  @override
  Widget build(BuildContext context) {
    final features = ShellScope.of(context).features;

    return WidgetsApp(
      title: window.title,
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
      home: Builder(builder: window.builder),
      builder: (context, child) => FerretTheme(
        child: ScreenSizeScope(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
