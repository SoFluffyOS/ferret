/// How a receive session ended, when this device didn't end it itself.
enum LocalSendSessionEnd {
  /// Every accepted file arrived and was saved.
  finished,

  /// The sender cancelled, before or after the offer was accepted.
  cancelledBySender,

  /// The sender went quiet before sending everything.
  stalled,

  /// A received file couldn't be saved on this device.
  storageFailed,
}
