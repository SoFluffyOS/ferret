import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/drop_target_region.dart';

/// Files dropped on the list but on no device in particular go to every
/// connected device.
class SidebarDropOnAll extends StatelessWidget {
  const SidebarDropOnAll({
    super.key,
    required this.devices,
    required this.child,
  });

  final List<DeviceStatus> devices;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final target = WindowDropTargets.everyone(devices);
    if (target == null) {
      return child;
    }

    return DropTargetRegion(target: target, child: child);
  }
}
