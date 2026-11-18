/// How freely the platform lets an app read the clipboard.
enum ClipboardAccess {
  /// Reads and change events work at any time (macOS, Windows, Linux).
  always,

  /// Reads work only while the app is in front, and change events only fire
  /// for copies made inside the app (Android 10 and later).
  foreground,

  /// Every read may ask the user first, so read only when they ask (iOS).
  onRequest;

  /// Whether copies made in other apps can be noticed and read on their own.
  bool get watchesOtherApps => this == always;
}
