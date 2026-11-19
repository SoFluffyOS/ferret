/// What this device's camera can do for the app right now.
class CameraAbilities {
  const CameraAbilities({required this.photo, required this.document});

  const CameraAbilities.none() : photo = false, document = false;

  factory CameraAbilities.fromMap(Object? map) {
    if (map is! Map) {
      return const .none();
    }

    return CameraAbilities(
      photo: map['photo'] == true,
      document: map['document'] == true,
    );
  }

  /// A camera and an app to take a photo with.
  final bool photo;

  /// An on-device document scanner (VisionKit on iPhone).
  final bool document;
}
