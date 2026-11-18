/// How ringing one connected device is doing, from the last round trip.
enum RingHealth {
  /// No answer yet.
  unknown,

  /// It rings out loud, even on silent.
  loud,

  /// It rings, but follows its silent switch or Do Not Disturb.
  followsSilent,

  /// It rings only while Ferret is open on it (iPhone).
  needsAppOpen,

  /// Its owner allowed ringing on silent, but the system permission is off.
  needsPermission,

  /// It didn't answer the last request.
  notAnswering,

  /// The last ring couldn't play a sound.
  noSound,

  /// Ferret on it can't ring.
  unsupported,
}
