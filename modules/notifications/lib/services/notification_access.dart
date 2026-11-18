/// The phone's notification access switch, which only the person can flip.
abstract interface class NotificationAccess {
  Future<bool> isAccessGranted();

  /// Android 13+ probably blocks the switch because Ferret was installed
  /// from a file ("restricted settings").
  Future<bool> mayBeRestricted();

  Future<void> openAccessSettings();

  Future<void> openAppInfo();
}
