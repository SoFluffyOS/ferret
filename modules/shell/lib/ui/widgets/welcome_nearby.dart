import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/privacy_line.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Under the devices near you while nothing is paired yet: what to do when
/// the one you want isn't listed, and the privacy promise.
class WelcomeNearby extends StatelessWidget {
  const WelcomeNearby({super.key, required this.onPairWithCode});

  final VoidCallback onPairWithCode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.d16,
        Spacing.d16,
        Spacing.d16,
        Spacing.d8,
      ),
      child: Column(
        children: [
          Text(
            l10n.nearbyNotTheOne,
            textAlign: .center,
            style: typography.base2.copyWith(color: palette.mutedText),
          ),
          Spacing.v6,
          Tappable(
            onTap: onPairWithCode,
            child: Text(
              l10n.pairShowCode,
              style: typography.base2.copyWith(color: palette.link),
            ),
          ),
          Spacing.v24,
          const PrivacyLine(),
        ],
      ),
    );
  }
}
