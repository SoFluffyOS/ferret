import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/sidebar_badge.dart';
import 'package:shell/ui/widgets/sidebar_row.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A paired device in a window's device list: its kind, its name, and a dot
/// that says whether it is connected.
class SidebarDeviceRow extends StatelessWidget {
  const SidebarDeviceRow({
    super.key,
    required this.status,
    required this.onTap,
    this.isSelected = false,
    this.needsAttention = false,
    this.badge = 0,
    this.isDropHovered = false,
    this.tooltip,
  });

  final DeviceStatus status;
  final VoidCallback onTap;

  /// Whether the pane shows this device's own page. While one of its
  /// sections is open, that section's line is the filled one.
  final bool isSelected;

  /// A feature that is on isn't working with this device.
  final bool needsAttention;

  /// What waits in its sections, shown while they are folded away.
  final int badge;

  /// Files are dragged over it: a connected device says it takes them, an
  /// offline one that it can't.
  final bool isDropHovered;

  /// Its connection in words, such as "Last seen 12 min ago".
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final device = status.device;
    final dotColor = switch ((status.isConnected, needsAttention)) {
      (false, _) when status.isReconnecting => palette.warning,
      (false, _) => palette.mutedText.withValues(alpha: 0.5),
      (true, true) => palette.warning,
      (true, false) => palette.success,
    };

    // What the dot's colour says, in words: for a screen reader, and for
    // anyone who can't tell the colours apart, on hover.
    final l10n = context.shellL10n;
    final dotInWords = switch ((status.isConnected, needsAttention)) {
      (false, _) when status.isReconnecting => l10n.deviceReconnecting,
      (false, _) => l10n.deviceOffline,
      (true, true) => l10n.deviceNeedsAttention,
      (true, false) => l10n.deviceConnected,
    };

    final takesDrop = isDropHovered && status.isConnected;
    final refusesDrop = isDropHovered && !status.isConnected;

    return SidebarRow(
      label: switch (takesDrop) {
        true => l10n.dropSendTo(device.name),
        false => device.name,
      },
      icon: deviceIconFor(device.formFactor, device.platform),
      isSelected: isSelected,
      isDimmed: !status.isConnected && !status.isReconnecting,
      isDropTarget: takesDrop,
      tooltip: tooltip ?? dotInWords,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: .min,
        children: [
          if (badge > 0) ...[SidebarBadge(badge), Spacing.h8],
          if (refusesDrop)
            Text(
              l10n.dropTileOffline,
              style: context.fluffyTheme.typography.caption1.copyWith(
                color: palette.mutedText,
              ),
            ),
          if (!refusesDrop)
            DecoratedBox(
              decoration: BoxDecoration(color: dotColor, shape: .circle),
              child: SizedBox.square(dimension: Spacing.d8),
            ),
        ],
      ),
    );
  }
}
