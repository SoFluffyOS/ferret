/// The media feature's settings keys.
abstract final class MediaSettings {
  /// Whether this device shares what it plays and accepts remote control.
  static const share = 'media.share';

  /// Whether this device shows what other devices play.
  static const showRemote = 'media.show_remote';

  /// Whether this device pauses its own players while a call rings or goes
  /// on, and plays them again after.
  static const pauseOnCall = 'media.pause_on_call';
}
