/// Why a Quick Share connection stopped.
enum QuickShareFailure {
  /// Nobody answered at the address, or the connection dropped.
  unreachable,

  /// The key exchange didn't complete.
  handshake,

  /// An encrypted frame didn't verify: wrong keys, a replay or tampering.
  tampered,

  /// The other device sent something the protocol doesn't allow.
  protocol,

  /// The other device went quiet.
  timedOut,
}
