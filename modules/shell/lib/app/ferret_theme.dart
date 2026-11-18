import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

const _ferretBlue = Color(0xFF0A66D6);

/// Ferret's look for one view: light or dark as the system says, the
/// app's blue, and the text style everything starts from.
class FerretTheme extends StatelessWidget {
  const FerretTheme({super.key, required this.child});

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
          child: child,
        ),
      ),
    );
  }
}
