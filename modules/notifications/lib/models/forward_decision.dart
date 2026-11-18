/// Whether a phone notification goes to the computer, and if not, why.
enum ForwardDecision {
  forward,

  /// Mirroring is off on this device.
  disabled,

  /// Ongoing, a foreground service, quiet, a group summary or empty.
  noise,

  /// The person didn't pick the app.
  appNotAllowed,

  /// The person is using the phone right now and sees it there.
  deviceInUse,
}
