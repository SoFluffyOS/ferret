/// Opens a shared link on another device, as Continue on does, for a
/// feature that only sends: the share sheet's send picker offers it next
/// to sending the link as text.
abstract interface class LinkOpener {
  /// Whether [deviceId] is connected and can open links sent to it.
  bool canOpenOn(String deviceId);

  /// Opens the link in [text] on [deviceId]. Says so itself when it
  /// couldn't.
  Future<void> open(String deviceId, String text);
}
