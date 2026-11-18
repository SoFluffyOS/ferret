/// Drop's settings keys and defaults.
abstract final class DropSettings {
  /// Accept files and text from paired devices without asking.
  static const autoAccept = 'drop.auto_accept';

  /// Where received files go: a folder path on desktop, or the folder name
  /// inside Downloads on Android.
  static const receiveFolder = 'drop.receive_folder';

  static const defaultFolderName = 'Ferret';

  /// Work with LocalSend devices at all: list them as send targets and
  /// offer to receive from them. On by default; nothing is sent on the
  /// network until someone looks for devices or turns receiving on.
  static const localSendEnabled = 'drop.localsend_enabled';

  /// Keep receiving from LocalSend devices after a restart. Off by
  /// default; the 10 minute window is never stored.
  static const localSendReceiveAlways = 'drop.localsend_receive_always';

  /// Offer to become visible to Quick Share on Android phones. On by
  /// default on computers; nothing is sent on the network until someone
  /// turns visibility on, and that is never stored.
  static const quickShareEnabled = 'drop.quickshare_enabled';
}
