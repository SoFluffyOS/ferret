/// Whether a phone notification goes to the computer, and if not, why.
enum ForwardDecision {
  forward,

  /// Mirroring is off on this device.
  disabled,

  /// Ongoing, a foreground service, media controls, quiet, a group summary
  /// or empty.
  noise,

  /// The person muted the app, or picked only other apps.
  appNotAllowed,

  /// The person is using the phone right now and sees it there.
  deviceInUse,
}
