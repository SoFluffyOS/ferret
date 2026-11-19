/// What a feature is in the middle of, for the one place that sums it up
/// for the whole app: the menubar icon on a Mac.
class FeatureBusy {
  const FeatureBusy({
    this.progress,
    this.peerName = '',
    this.isSending = true,
    this.waitingCount = 0,
    this.waitingName = '',
    this.finishedCount = 0,
    this.screenSeenBy = '',
    this.controlledBy = '',
  });

  /// How far the running transfers got together, 0 to 1, or null when
  /// nothing is running.
  final double? progress;

  /// The device the running transfer is with, or empty when there are
  /// several or it has no name.
  final String peerName;

  /// Whether the running transfer leaves this device (true) or arrives.
  final bool isSending;

  /// How many requests wait for the person to answer.
  final int waitingCount;

  /// Who sent the request that waits, or empty when unknown.
  final String waitingName;

  /// How many transfers finished well since the app started. It only goes
  /// up, and never for one that failed or was cancelled: the icon shows a
  /// check each time it does.
  final int finishedCount;

  /// The device that sees this device's screen right now, or empty. The
  /// icon keeps a dot for as long as it does.
  final String screenSeenBy;

  /// The device that moves the pointer and types here right now, or
  /// empty. The icon keeps a dot for as long as it does.
  final String controlledBy;
}
