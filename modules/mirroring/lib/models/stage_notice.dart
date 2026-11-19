/// One line over the picture that says something once, then goes.
enum StageNotice {
  /// Ferret couldn't reach the phone, so this goes over the cable.
  viaCable,

  /// Over a cable the phone doesn't ask each time.
  cableNoAsk,

  /// The picture has been poor for a while.
  slow,

  /// This computer shows the plain JPEG picture.
  basicPicture,

  /// A click on a picture that can only be looked at.
  viewOnly,

  /// A picture of the screen was saved to a file.
  screenshotSaved,

  /// The picture of the screen couldn't be saved.
  screenshotFailed,

  /// The phone's owner is asked to let this computer control it.
  controlAsking,

  /// Clicks and keys reach the phone now.
  controlAllowed,

  /// The phone's owner said no to control.
  controlDenied,

  /// Nobody answered on the phone about control.
  controlTimedOut,

  /// The phone's owner stopped control.
  controlStopped,
}
