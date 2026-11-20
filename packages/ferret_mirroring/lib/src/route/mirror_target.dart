/// A device a route can show.
class MirrorTarget {
  const MirrorTarget({
    required this.routeId,
    required this.id,
    required this.name,
    this.ferretDeviceId,
    this.wireless = false,
    this.camera = false,
    this.display = false,
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

  /// Its camera and microphone rather than its screen.
  final bool camera;

  /// The extra display the device lends this one: this screen shows it,
  /// and the pointer and keys here drive it.
  final bool display;

  @override
  bool operator ==(Object other) =>
      other is MirrorTarget &&
      other.routeId == routeId &&
      other.id == id &&
      other.camera == camera &&
      other.display == display;

  @override
  int get hashCode => Object.hash(routeId, id, camera, display);
}
