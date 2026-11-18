/// How a command to a remote player ended.
enum CommandOutcome {
  ok,

  /// The device didn't answer, or it disconnected.
  unreachable,

  /// The player closed in the meantime.
  unknownPlayer,

  /// The device stopped sharing its media.
  notShared,

  /// The player can't do that.
  unsupported,
  failed,
}

/// Why "Continue here" didn't work.
enum ContinueFailure {
  /// Ferret can't open this kind of item here, such as a local file.
  noLink,

  /// The device didn't answer, or it disconnected.
  unreachable,

  /// The player closed in the meantime.
  playerGone,

  /// The device stopped sharing its media.
  notShared,

  /// No app here could open the item.
  openFailed,
}

/// The result of "Continue here".
sealed class ContinueOutcome {
  const ContinueOutcome();
}

final class ContinueOpened extends ContinueOutcome {
  const ContinueOpened(this.uri);

  final Uri uri;
}

final class ContinueFailed extends ContinueOutcome {
  const ContinueFailed(this.reason);

  final ContinueFailure reason;
}
