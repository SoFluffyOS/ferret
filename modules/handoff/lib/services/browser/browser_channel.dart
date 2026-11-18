/// One connection from a browser extension, as the bridge sees it: text
/// messages in, JSON out.
abstract interface class BrowserChannel {
  /// The extension origin the connection was accepted with.
  String get origin;

  /// Text messages from the extension. Done when it disconnects.
  Stream<String> get messages;

  void send(Map<String, Object?> message);

  Future<void> close([int code, String reason]);
}

/// Close codes the bridge uses, in the 4000 range WebSocket leaves to apps.
abstract final class BrowserCloseCode {
  static const protocolError = 4000;
  static const unauthorized = 4001;
  static const revoked = 4003;
  static const rateLimited = 4008;
  static const tooLarge = 1009;
  static const goingAway = 1001;
}
