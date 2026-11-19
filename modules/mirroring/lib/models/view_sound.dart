/// What happens to a device's sound on the way its screen arrives.
enum SoundWay {
  /// The device plays it in one place: here, or on itself. Changing that
  /// opens the picture again. The cable, where the owner isn't asked.
  moves,

  /// It plays on the device and here at once, when its owner allowed it.
  copies,

  /// The way brings no sound.
  none,
}

/// Where the computer stands with the sound of the screen it shows.
enum ViewSound {
  /// Not asked for, or turned off here.
  off,

  /// Asked for; nothing has arrived yet.
  starting,

  /// The device's sound plays on this computer.
  playing,

  /// The device can't send its sound: its Android or its Ferret is too
  /// old.
  unsupported,

  /// Its owner hasn't allowed sound to be sent.
  notAllowed,

  /// Capturing the sound failed on the device.
  failed,

  /// This computer couldn't play it.
  noOutput,
}
