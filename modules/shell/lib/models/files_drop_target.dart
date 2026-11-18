/// Something on screen that dragged files can be dropped on. Tag its widget
/// with `DropTargetRegion` so a drag over it finds it.
sealed class FilesDropTarget {
  const FilesDropTarget();

  /// Whether a drop here would be sent somewhere right now.
  bool get acceptsDrop;
}

/// One paired device.
final class DeviceDropTarget extends FilesDropTarget {
  const DeviceDropTarget({
    required this.deviceId,
    required this.name,
    required this.isConnected,
  });

  final String deviceId;
  final String name;
  final bool isConnected;

  @override
  bool get acceptsDrop => isConnected;

  @override
  bool operator ==(Object other) =>
      other is DeviceDropTarget &&
      other.deviceId == deviceId &&
      other.name == name &&
      other.isConnected == isConnected;

  @override
  int get hashCode => Object.hash(deviceId, name, isConnected);
}

/// Every connected device at once.
final class AllDevicesDropTarget extends FilesDropTarget {
  const AllDevicesDropTarget();

  @override
  bool get acceptsDrop => true;

  @override
  bool operator ==(Object other) => other is AllDevicesDropTarget;

  @override
  int get hashCode => (AllDevicesDropTarget).hashCode;
}

/// A window's content pane, which sends to [target]: the device it shows,
/// or everyone. Kept apart from [target] itself so the pane and the device
/// row each light up only while the pointer is over them.
final class PaneDropTarget extends FilesDropTarget {
  const PaneDropTarget(this.target);

  final FilesDropTarget target;

  @override
  bool get acceptsDrop => target.acceptsDrop;

  @override
  bool operator ==(Object other) =>
      other is PaneDropTarget && other.target == target;

  @override
  int get hashCode => Object.hash(PaneDropTarget, target);
}
