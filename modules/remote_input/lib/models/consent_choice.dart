/// What the computer's owner answered when a device asked for control.
enum ConsentChoice {
  /// This time only; the device asks again next time.
  allowOnce,

  /// This time and every time after, until revoked in Settings.
  always,

  /// Not now.
  deny,
}
