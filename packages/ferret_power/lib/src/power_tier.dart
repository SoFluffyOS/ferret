/// How much this phone lets Ferret do beyond a normal app.
enum PowerTier {
  /// A normal app with the permissions Android gives every app.
  standard,

  /// Commands run as the shell user through the Shizuku service.
  shizuku,

  /// Commands run through `su`.
  root;

  /// Whether copies made in other apps can be read while Ferret is in the
  /// background.
  bool get readsClipboardInBackground => this != standard;
}
