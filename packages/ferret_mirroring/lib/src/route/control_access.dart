/// Where a device that asks its owner before it can be controlled stands
/// with this computer.
enum ControlAccess {
  /// It can be controlled once its owner says yes: ask.
  canAsk,

  /// Its owner is being asked.
  asking,

  /// Clicks and keys go through.
  allowed,

  /// Its owner said no. Asking again is fine.
  denied,

  /// Nobody answered on the device in time.
  timedOut,

  /// Nothing on the device can take clicks until its owner sets it up
  /// there.
  needsSetup,

  /// The device can't be controlled at all.
  unsupported,

  /// Its owner stopped control. Asking again is fine.
  stopped;

  /// Asking now would put the question to the device's owner.
  bool get canAskNow =>
      this == canAsk || this == denied || this == timedOut || this == stopped;
}

/// A feed whose device asks its owner before it can be controlled. It says
/// where that stands with [FeedControlChanged].
abstract interface class ControlAsking {
  /// Puts the question to the device's owner.
  Future<void> askControl();
}
