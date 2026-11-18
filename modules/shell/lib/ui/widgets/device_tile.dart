import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/feature_chip.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One paired device: name, whether it is connected (or when it was last
/// seen), each feature's health, and a way to find out why it isn't
/// connected.
class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.status,
    this.chips = const [],
    this.onTap,
    this.onWhy,
  });

  final DeviceStatus status;
  final List<FeatureChip> chips;
  final VoidCallback? onTap;
  final VoidCallback? onWhy;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final device = status.device;
    final dotColor = switch (status.isConnected) {
      true => palette.success,
      false => palette.mutedText,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: SurfaceCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              deviceIconFor(device.formFactor, device.platform),
              size: Spacing.d24,
              color: palette.text,
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    device.name,
                    style: typography.base1.copyWith(color: palette.text),
                    overflow: .ellipsis,
                  ),
                  Spacing.vertical(Spacing.d2),
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: .circle,
                        ),
                        child: SizedBox.square(dimension: Spacing.d6),
                      ),
                      Spacing.h6,
                      Expanded(
                        child: Text(
                          _subtitle(context),
                          style: typography.caption1.copyWith(
                            color: palette.mutedText,
                          ),
                          overflow: .ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (status.isConnected && chips.isNotEmpty) ...[
                    Spacing.v6,
                    Row(children: chips),
                  ],
                ],
              ),
            ),
            if (!status.isConnected && onWhy != null)
              Tappable(
                onTap: onWhy,
                child: Padding(
                  padding: EdgeInsets.all(Spacing.d4),
                  child: Text(
                    context.shellL10n.deviceWhy,
                    style: typography.caption1.copyWith(color: palette.accent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final l10n = context.shellL10n;
    if (status.isConnected) {
      return l10n.deviceConnected;
    }

    final lastSeen = status.device.lastSeen;
    if (lastSeen == null) {
      return l10n.deviceOffline;
    }

    final elapsed = DateTime.now().difference(lastSeen);
    return switch (elapsed) {
      Duration(inMinutes: < 1) => l10n.deviceLastSeenJustNow,
      Duration(inHours: < 1) => l10n.deviceLastSeenMinutes(elapsed.inMinutes),
      Duration(inDays: < 1) => l10n.deviceLastSeenHours(elapsed.inHours),
      _ => l10n.deviceLastSeenDays(elapsed.inDays),
    };
  }
}
