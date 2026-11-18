/// Whether the local bridge for the browser extension is up.
enum BrowserBridgeStatus {
  /// Turned off in Settings, or not offered on this device.
  off,

  /// Listening on [BrowserBridgeState.port].
  listening,

  /// Every port in the range is taken by another app.
  failed,
}

class BrowserBridgeState {
  const BrowserBridgeState(this.status, {this.port});

  static const off = BrowserBridgeState(.off);

  final BrowserBridgeStatus status;
  final int? port;
}
