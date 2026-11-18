/// How sending to a Quick Share receiver ended.
enum QuickShareSendResult {
  /// Everything was sent and the receiver didn't object.
  sent,

  /// The receiver said no.
  declined,

  /// The receiver can't take this kind of content.
  unsupported,

  /// The receiver has no room for it.
  noSpace,

  /// Nobody answered on the receiver in time.
  timedOut,

  /// This device cancelled.
  cancelled,

  /// The receiver cancelled or went away.
  cancelledByReceiver,
}
