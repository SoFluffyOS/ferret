/// A device a route can show.
class MirrorTarget {
  const MirrorTarget({
    required this.routeId,
    required this.id,
    required this.name,
    this.ferretDeviceId,
    this.wireless = false,
  });

  final String routeId;

  /// The route's own handle, such as an adb serial.
  final String id;

  final String name;

  /// The Ferret device it is, when known, so the same phone reached two
  /// ways shows as one.
  final String? ferretDeviceId;

  /// Reached over the network rather than a cable.
  final bool wireless;

  @override
  bool operator ==(Object other) =>
      other is MirrorTarget && other.routeId == routeId && other.id == id;

  @override
  int get hashCode => Object.hash(routeId, id);
}
