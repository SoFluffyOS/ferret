import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/widgets/drop_target_region.dart';
import 'package:shell/view_models/view_models.dart';

/// A device's row on Home as a place to drop on, such as an item dragged
/// off the shelf: tinted while the drag is over it and it can take it.
class DeviceDropHover extends StatelessWidget {
  const DeviceDropHover({super.key, required this.target, required this.child});

  final DeviceDropTarget target;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isHovered = context.select<OsDropViewModel?, bool>(
      (drop) => drop?.hovered == target && target.acceptsDrop,
    );
    final palette = context.palette;

    return DropTargetRegion(
      target: target,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: ShapeDecoration(
          color: switch (isHovered) {
            true => palette.accent.withValues(alpha: 0.12),
            false => palette.accent.withValues(alpha: 0),
          },
          shape: Corners.shape(Corners.card),
        ),
        child: child,
      ),
    );
  }
}
