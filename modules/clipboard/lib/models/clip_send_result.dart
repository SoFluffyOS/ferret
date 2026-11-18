/// What happened when this device tried to send its clipboard.
enum ClipSendResult {
  /// At least one device got it.
  sent,

  /// The clipboard is empty, holds something other than text or an image,
  /// or this platform didn't let Ferret read it.
  nothingToSend,

  /// It is the same thing that was just synced.
  duplicate,

  /// The source app marked it as private and private items are off.
  sensitive,

  /// It is an image and images are off.
  imagesOff,

  /// It is bigger than the size limit.
  tooLarge,

  /// No connected device takes clipboard items.
  noDevices,

  /// Every device that should have got it failed to.
  failed,
}
