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
}
