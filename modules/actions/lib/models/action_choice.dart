/// The owner's answer to a device that asks to run an action.
enum ActionChoice {
  /// This time and every next time, for this action from this device.
  always,
  allowOnce,
  deny,
}
