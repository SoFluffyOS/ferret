/// What happened when this device tried to open an activity.
enum OpenResult {
  opened,

  /// Can't open right now without the user, such as Android blocking apps
  /// from starting other apps from the background. Becomes a notice.
  deferred,

  /// Nothing here can open it.
  failed,
}
