/// What a phone's Photos page shows.
enum GalleryState {
  loading,
  offline,

  /// The phone's Ferret has no Photos, or is too old.
  unsupported,

  /// The phone didn't answer.
  failed,

  /// The phone's owner hasn't shared photos with this computer.
  notAllowed,

  /// Ferret on the phone has no photo access from the system.
  noPermission,

  /// The phone can't read photos right now, such as an iPhone with Ferret
  /// in the background.
  unavailable,

  empty,
  photos,
}
