/// What the home card asks for. There is a card only when one of these is
/// true right now.
enum PowerPrompt {
  /// Shizuku is installed but not running.
  startShizuku,

  /// Shizuku is running and Ferret isn't using it yet.
  allowShizuku,

  /// Ferret was using Shizuku and it stopped, such as after a restart.
  shizukuStopped,

  /// Ferret was using Shizuku and lost its permission.
  shizukuRevoked,

  /// The phone is rooted and Ferret isn't using root.
  useRoot,

  /// Ferret was using root and `su` now says no.
  rootLost;

  /// Something that worked stopped working, rather than an offer: the card
  /// stays until it is fixed or the tier is turned off.
  bool get isProblem =>
      this == shizukuStopped || this == shizukuRevoked || this == rootLost;
}
