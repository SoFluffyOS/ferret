import 'package:engine/engine.dart';
import 'package:shell/models/models.dart';

/// What a file drag in the window can land on.
abstract final class WindowDropTargets {
  static DeviceDropTarget device(DeviceStatus status) => DeviceDropTarget(
    deviceId: status.device.id,
    name: status.device.name,
    isConnected: status.isConnected,
  );

  /// Where files dropped on no device in particular go: the one connected
  /// device by its name, every connected one when there are several, and
  /// nowhere when none is.
  static FilesDropTarget? everyone(List<DeviceStatus> devices) {
    final connected = [
      for (final status in devices)
        if (status.isConnected) status,
    ];

    return switch (connected) {
      [] => null,
      [final only] => device(only),
      _ => const AllDevicesDropTarget(),
    };
  }
}
