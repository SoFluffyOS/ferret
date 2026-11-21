import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/widgets/device_tile.dart';
import 'package:shell/ui/widgets/drop_target_region.dart';
import 'package:shell/view_models/view_models.dart';

/// A device's card on Home as a place to drop on, such as an item dragged
/// off the shelf: while the drag is over it, the card says "Drop to send
/// to Pixel 7" over itself, the shelf box's look, or "Pixel 7 is offline"
/// in grey where it can't take it, and the drop is refused.
class DeviceDropHover extends StatelessWidget {
  const DeviceDropHover({super.key, required this.target, required this.child});

  final DeviceDropTarget target;

  /// The device's [DeviceTile].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isHovered = context.select<OsDropViewModel?, bool>(
      (drop) => drop?.hovered == target,
    );
    final l10n = context.shellL10n;
    final accepts = target.acceptsDrop;

    return DropTargetRegion(
      target: target,
      child: Stack(
        children: [
          child,
          // Over the card only, not the gap under it.
          Positioned.fill(
            bottom: DeviceTile.gap,
            child: DropOverlay(
              radius: Corners.card,
              refused: !accepts,
              icon: switch (accepts) {
                true => LucideIcons.upload,
                false => LucideIcons.wifiOff,
              },
              label: switch ((isHovered, accepts)) {
                (false, _) => null,
                (true, true) => l10n.dropToSendTo(target.name),
                (true, false) => l10n.dropDeviceOffline(target.name),
              },
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}
