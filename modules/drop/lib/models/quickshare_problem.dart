/// Why this device couldn't become visible to Quick Share, to explain it
/// in plain words.
enum QuickShareProblem {
  /// No port could be opened, such as when a firewall blocks it.
  cannotListen,

  /// The network announcement couldn't be sent, so phones wouldn't find
  /// this device.
  cannotAdvertise,
}
