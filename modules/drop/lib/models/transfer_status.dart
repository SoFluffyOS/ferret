/// Where a transfer is. The UI shows each one in plain words.
enum TransferStatus {
  /// Waiting for the other side to accept, or for this side to answer.
  waiting,

  /// Bytes are moving.
  transferring,

  /// The last bytes arrived; the receiver is checking the SHA-256.
  verifying,

  /// Every file was verified and saved, or the text arrived.
  done,

  /// Stopped by an error. [Transfer.failure] says why; most can be retried.
  failed,

  /// Someone cancelled it.
  cancelled;

  bool get isActive => switch (this) {
    waiting || transferring || verifying => true,
    done || failed || cancelled => false,
  };
}
