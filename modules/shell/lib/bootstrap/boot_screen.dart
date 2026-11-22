import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/ferret_theme.dart';
import 'package:shell/bootstrap/splash_glyph_painter.dart';
import 'package:shell/bootstrap/splash_look.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What Ferret draws while it gets ready: on a phone, the launch screen's
/// ferret on sable, exactly where the system drew it; on a computer, the
/// window's own background. A quiet spinner joins only when getting ready
/// takes longer than [spinnerAfter], as it can on a slow phone.
class BootScreen extends StatefulWidget {
  const BootScreen({
    super.key,
    required this.look,
    this.spinnerAfter = const Duration(seconds: 1),
  });

  /// The launch screen to carry on, or null for a window's background.
  final SplashLook? look;

  final Duration spinnerAfter;

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  late final Timer _timer;
  bool _isSlow = false;

  static const _spinnerFade = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.spinnerAfter, () => setState(() => _isSlow = true));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nothing here reads in a direction; the Stack just needs one.
    return Directionality(
      textDirection: .ltr,
      child: FerretTheme(
        child: Builder(
          builder: (context) => switch (widget.look) {
            final look? => _splash(look),
            null => _window(context),
          },
        ),
      ),
    );
  }

  Widget _splash(SplashLook look) {
    // The spinner sits a little under the ferret's lowest point.
    final belowGlyph = (look.anchor.dy - _glyphBottom).abs() * look.scale;

    return ColoredBox(
      color: SplashLook.background,
      child: Stack(
        fit: .expand,
        children: [
          ExcludeSemantics(
            child: CustomPaint(painter: SplashGlyphPainter(look)),
          ),
          Center(
            child: Transform.translate(
              offset: Offset(0, belowGlyph + Spacing.d48),
              child: _spinner(SplashGlyphPainter.fur),
            ),
          ),
        ],
      ),
    );
  }

  Widget _window(BuildContext context) {
    return ColoredBox(
      color: context.palette.background,
      child: Center(child: _spinner(context.palette.mutedText)),
    );
  }

  Widget _spinner(Color color) {
    final spinner = switch (_isSlow) {
      true => Semantics(
        label: lookupShellLocalizations(
          AppLocale.pick(ShellLocalizations.supportedLocales),
        ).bootStarting,
        liveRegion: true,
        child: FluffySpinner(
          size: Spacing.d20,
          strokeWidth: Spacing.d2,
          color: color,
        ),
      ),
      false => SizedBox.square(dimension: Spacing.d20),
    };

    return AnimatedOpacity(
      opacity: switch (_isSlow) {
        true => 1,
        false => 0,
      },
      duration: _spinnerFade,
      child: spinner,
    );
  }

  /// Where the ferret's body ends on the branding canvas.
  static const _glyphBottom = 924.0;
}
