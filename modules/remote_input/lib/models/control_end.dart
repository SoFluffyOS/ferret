/// How a time of being controlled ended, for the history.
enum ControlEnd {
  /// The controller closed its touchpad.
  controllerDone,

  /// Someone pressed Stop on this computer.
  stoppedHere,

  /// Nothing happened for a long time.
  idle,

  /// The owner revoked the device or turned remote input off.
  revoked,

  /// The connection dropped.
  lostConnection,

  /// Injecting input stopped working, such as a permission turned off.
  failed,
}
