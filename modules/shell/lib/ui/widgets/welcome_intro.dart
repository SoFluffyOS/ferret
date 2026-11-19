import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The welcome above the devices near you on a first launch: what Ferret
/// is for, and that pairing one of them is all it takes.
class WelcomeIntro extends StatelessWidget {
  const WelcomeIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        PageInsets.row,
        Spacing.d12,
        PageInsets.row,
        Spacing.d4,
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            l10n.welcomeTitle,
            style: typography.title3.copyWith(color: palette.text),
          ),
          Spacing.v4,
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: PaneWidths.narrowContent,
            ),
            child: Text(
              l10n.welcomeNearbyBody,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ),
        ],
      ),
    );
  }
}
