import 'package:feature_kit/layout/layout.dart';
import 'package:feature_kit/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Features that work in our tests but haven't met enough real devices
/// yet. Each one's switch, button or prompt carries a [BetaTag], or says
/// "(beta)" where only words fit.
enum BetaFeature {
  /// A phone, tablet or computer as another computer's extra display.
  secondDisplay,

  /// One keyboard and mouse moving between computers.
  sharedInput,

  /// The phone's camera in a computer's window, over Wi-Fi.
  wifiCamera,

  /// A computer controlling the phone it shows, over Wi-Fi.
  wifiControl,

  /// The phone's sound with Show screen, over Wi-Fi.
  wifiSound,

  /// Show screen: a phone sharing its screen with a computer over Wi-Fi.
  wifiScreen,

  /// Show screen over a USB cable.
  cableScreen,

  /// A computer as a screen receiver, such as AirPlay from an iPhone.
  screenReceiver;

  /// The features still in beta. Once one has met enough real devices,
  /// take it out of this set: every tag and "(beta)" for it goes away.
  static const _inBeta = {
    secondDisplay,
    sharedInput,
    wifiCamera,
    wifiControl,
    wifiSound,
    wifiScreen,
    cableScreen,
    screenReceiver,
  };

  bool get isBeta => _inBeta.contains(this);

  /// [text] with "(beta)" after it while [isBeta], for a tooltip or a menu
  /// item, where a tag doesn't fit. [inBeta] puts it there in the user's
  /// language. Never on a button's own label: those stay short.
  String label(String text, String Function(String text) inBeta) =>
      switch (isBeta) {
        true => inBeta(text),
        false => text,
      };
}

/// A small, quiet "Beta" beside a feature's switch or prompt while
/// [feature] is in beta; nothing once it isn't. Resting on it says why, and
/// screen readers say both.
class BetaTag extends StatelessWidget {
  const BetaTag(
    this.feature, {
    super.key,
    required this.label,
    required this.tooltip,
  });

  final BetaFeature feature;

  /// "Beta", in the user's language.
  final String label;

  /// Why: it works in our tests, not yet on enough real devices.
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    if (!feature.isBeta) {
      return const SizedBox.shrink();
    }

    final palette = context.palette;

    return FluffyTooltip(
      message: tooltip,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: palette.mutedText.withValues(alpha: 0.12),
            shape: Corners.shape(Corners.capsule),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.d6,
              vertical: Spacing.d1,
            ),
            child: Text(
              label,
              maxLines: 1,
              style: context.fluffyTheme.typography.caption2.copyWith(
                color: palette.mutedText,
                fontWeight: .w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
