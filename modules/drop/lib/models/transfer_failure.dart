/// Why a transfer stopped, to explain it in plain words.
enum TransferFailure {
  /// The other device said no.
  declined,

  /// Nobody answered the offer in time.
  timedOut,

  /// The session dropped. The transfer resumes when the device is back.
  disconnected,

  /// The device isn't connected right now.
  notConnected,

  /// The device doesn't offer Drop, such as an old version.
  unsupported,

  /// Reading or writing a file failed, such as a full disk.
  storage,

  /// The received data didn't match the sender's SHA-256.
  checksum,

  /// The file changed or disappeared while it was being sent.
  sourceChanged,

  /// The other device cancelled.
  cancelledByPeer,

  /// The other device no longer knows this transfer.
  unknownTransfer,

  /// The other device sent something unexpected.
  protocol,
}
