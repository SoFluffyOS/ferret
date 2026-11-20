import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Something near that a feature can act on without pairing, such as a
/// phone on a cable: its name, how it is here, and the one thing to do
/// with it.
class NearbyFeatureTile extends StatelessWidget {
  const NearbyFeatureTile({super.key, required this.row});

  final FeatureNearbyRow row;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: SurfaceCard(
        child: Row(
          children: [
            Icon(row.icon, size: Spacing.d24, color: palette.text),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    row.title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: typography.base1.copyWith(color: palette.text),
                  ),
                  Text(
                    row.detail,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Spacing.h12,
            GhostButton(
              mainAxisSize: .min,
              label: row.actionLabel,
              onPressed: row.onAction,
            ),
          ],
        ),
      ),
    );
  }
}
