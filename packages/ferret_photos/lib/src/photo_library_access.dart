/// What the system lets this app read in the photo library.
enum PhotoLibraryAccess {
  /// Every photo and video.
  full,

  /// Only what the person picked: Android 14's "Selected photos", or the
  /// iPhone's limited library. Asking again lets them pick more.
  limited,

  /// The person said no; only the system settings can change it now.
  denied,

  /// Nobody asked yet.
  notAsked,

  /// The library can't be read right now, such as an iPhone app in the
  /// background.
  unavailable,

  /// This platform has no photo library Ferret can read, such as a
  /// computer.
  unsupported;

  /// Whether photos can be listed at all.
  bool get canRead => this == full || this == limited;

  /// The access named [name], or [unavailable] for anything unknown.
  static PhotoLibraryAccess byNameOr(String? name) {
    for (final access in values) {
      if (access.name == name) {
        return access;
      }
    }

    return unavailable;
  }
}
