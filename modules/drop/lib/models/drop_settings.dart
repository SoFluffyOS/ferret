/// Drop's settings keys and defaults.
abstract final class DropSettings {
  /// Accept files and text from paired devices without asking.
  static const autoAccept = 'drop.auto_accept';

  /// Where received files go: a folder path on desktop, or the folder name
  /// inside Downloads on Android.
  static const receiveFolder = 'drop.receive_folder';

  static const defaultFolderName = 'Ferret';
}
