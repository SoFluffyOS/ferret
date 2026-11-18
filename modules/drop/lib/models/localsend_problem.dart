/// Why receiving from LocalSend couldn't start, to explain it in plain
/// words.
enum LocalSendProblem {
  /// No port could be opened, such as when a firewall blocks it.
  cannotListen,

  /// The certificate for this device couldn't be made or stored.
  noIdentity,
}
