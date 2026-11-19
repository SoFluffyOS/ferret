import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/widgets/battery_badge.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The top of a device's page: its icon, its name and the one thing that is
/// true about its connection right now.
class DeviceHeader extends StatelessWidget {
  const DeviceHeader({super.key, required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final device = status.device;
    final dotColor = switch (status.isConnected) {
      true => palette.success,
      false when status.isReconnecting => palette.warning,
      false when status.versionMismatch != null => palette.warning,
      false => palette.mutedText,
    };

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        Spacing.d0,
        Spacing.d8,
        Spacing.d0,
        Spacing.d16,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: ShapeDecoration(
              color: palette.surface,
              shape: Corners.shape(Corners.card),
            ),
            child: Padding(
              padding: EdgeInsets.all(Spacing.d12),
              child: Icon(
                deviceIconFor(device.formFactor, device.platform),
                size: Spacing.d24,
                color: palette.text,
              ),
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  device.name,
                  style: typography.title3.copyWith(color: palette.text),
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
                      child: SizedBox.square(dimension: Spacing.d8),
                    ),
                    Spacing.h6,
                    Flexible(
                      child: Text(
                        _statusLine(context.shellL10n),
                        style: typography.base2.copyWith(
                          color: palette.mutedText,
                        ),
                        overflow: .ellipsis,
                      ),
                    ),
                    if (status.battery case final battery?) ...[
                      Spacing.h8,
                      BatteryBadge(battery: battery),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLine(ShellLocalizations l10n) {
    if (status.isConnected) {
      return switch ((status.isWeak, status.isAway)) {
        (true, _) => l10n.deviceWeak,
        (false, true) => l10n.deviceAway,
        (false, false) => l10n.deviceConnected,
      };
    }

    if (status.isReconnecting) {
      return l10n.deviceReconnecting;
    }

    if (status.versionMismatch case final mismatch?) {
      return switch (mismatch.update) {
        .otherDevice => l10n.deviceUpdateThere,
        .thisDevice => l10n.deviceUpdateHere,
      };
    }

    return l10n.lastSeen(status.device.lastSeen);
  }
}
