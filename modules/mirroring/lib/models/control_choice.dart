/// What this phone's owner answered when a computer asked to control it.
enum ControlChoice {
  /// This time and every time after, until taken back in Settings.
  always,

  /// While the screen is shown this time.
  once,

  no,
}
