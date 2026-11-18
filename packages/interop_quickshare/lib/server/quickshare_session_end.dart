/// How a receive session ended, when it wasn't this device that ended it.
enum QuickShareSessionEnd {
  /// Every file and text arrived and was handed over.
  finished,

  /// The sender cancelled or took the offer back.
  cancelledBySender,

  /// The connection dropped or went silent before everything arrived.
  connectionLost,

  /// A file ended before all of its announced bytes arrived.
  incomplete,

  /// A file couldn't be written or saved on this device.
  storageFailed,

  /// The sender broke the protocol, or a frame failed its checks.
  protocolError,
}
