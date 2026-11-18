import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
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

  /// Its connection in words, such as "Last seen 12 min ago".
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final device = status.device;
    final dotColor = switch ((status.isConnected, needsAttention)) {
      (false, _) => palette.mutedText.withValues(alpha: 0.5),
      (true, true) => palette.warning,
      (true, false) => palette.success,
    };

    return SidebarRow(
      label: device.name,
      icon: deviceIconFor(device.formFactor, device.platform),
      isSelected: isSelected,
      isDimmed: !status.isConnected,
      tooltip: tooltip,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: .min,
        children: [
          if (badge > 0) ...[SidebarBadge(badge), Spacing.h8],
          DecoratedBox(
            decoration: BoxDecoration(color: dotColor, shape: .circle),
            child: SizedBox.square(dimension: Spacing.d8),
          ),
        ],
      ),
    );
  }
}
