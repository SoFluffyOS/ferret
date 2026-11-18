import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The first thing people see: what Ferret does, the privacy promise, and
/// the way to the other ways to pair. The devices near you sit right above
/// it, with the real next step.
class EmptyDevices extends StatelessWidget {
  const EmptyDevices({super.key, required this.onPair});

  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d8),
      child: SurfaceCard(
        padding: EdgeInsets.all(Spacing.d24),
        child: Column(
          children: [
            Icon(
              LucideIcons.arrowLeftRight,
              size: Spacing.d36,
              color: palette.accent,
            ),
            Spacing.v16,
            Text(
              l10n.welcomeTitle,
              textAlign: .center,
              style: typography.title2.copyWith(color: palette.text),
            ),
            Spacing.v8,
            Text(
              l10n.welcomeBody,
              textAlign: .center,
              style: typography.body2.copyWith(color: palette.mutedText),
            ),
            Spacing.vertical(Spacing.d20),
            Button(
              variant: .ghost,
              label: l10n.pairCantSee,
              titleExpand: .shrink,
              onPressed: onPair,
            ),
            Spacing.v16,
            Row(
              mainAxisAlignment: .center,
              children: [
                Icon(
                  LucideIcons.lock,
                  size: Spacing.d12,
                  color: palette.mutedText,
                ),
                Spacing.h6,
                Flexible(
                  child: Text(
                    l10n.welcomePrivacy,
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                ),
              ],
            ),
            Spacing.v4,
            Text(
              l10n.welcomePlatforms,
              style: typography.caption2.copyWith(color: palette.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
