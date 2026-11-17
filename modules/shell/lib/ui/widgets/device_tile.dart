import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One paired device: its icon, name and whether it is connected.
class DeviceTile extends StatelessWidget {
  const DeviceTile({super.key, required this.status, this.onTap});

  final DeviceStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final device = status.device;
    final subtitle = switch (status.isConnected) {
      true => context.shellL10n.deviceConnected,
      false => context.shellL10n.deviceOffline,
    };
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
                          subtitle,
                          style: typography.caption1.copyWith(
                            color: palette.mutedText,
                          ),
                        ),
                      ),
                    ],
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
