import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:transport/transport.dart';

/// An unpaired Ferret device on the network, ready to pair.
class NearbyTile extends StatelessWidget {
  const NearbyTile({super.key, required this.peer, required this.onTap});

  final DiscoveredPeer peer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final announce = peer.announce;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: SurfaceCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              deviceIconFor(announce.formFactor, announce.platform),
              size: Spacing.d24,
              color: palette.mutedText,
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    announce.name,
                    style: typography.base1.copyWith(color: palette.text),
                    overflow: .ellipsis,
                  ),
                  Spacing.vertical(Spacing.d2),
                  Text(
                    context.shellL10n.nearbyPairHint,
                    style: typography.caption1.copyWith(color: palette.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
