import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Shown before the first pairing.
class EmptyDevices extends StatelessWidget {
  const EmptyDevices({super.key, required this.onPair});

  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return SurfaceCard(
      padding: EdgeInsets.all(Spacing.d20),
      child: Column(
        children: [
          Icon(
            LucideIcons.arrowLeftRight,
            size: Spacing.d32,
            color: palette.accent,
          ),
          Spacing.v12,
          Text(
            l10n.homeNoDevicesTitle,
            style: typography.title3.copyWith(color: palette.text),
          ),
          Spacing.v6,
          Text(
            l10n.homeNoDevicesBody,
            textAlign: .center,
            style: typography.body2.copyWith(color: palette.mutedText),
          ),
          Spacing.v16,
          Button(
            variant: .primary,
            label: l10n.homePairDevice,
            onPressed: onPair,
          ),
        ],
      ),
    );
  }
}
