/// Where an update stands.
enum UpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  downloading,

  /// Checking the checksum, then the signature.
  verifying,
  installing,

  /// Installed; Ferret quits and a helper opens the new one.
  restarting,

  /// Android needs "Install unknown apps" for Ferret first.
  needsPermission,

  /// Android shows its own install prompt.
  handedToSystem,

  /// A Mac couldn't replace the app, so the checked DMG is open.
  openedForYou,
  failed;

  /// Whether something is under way that a new check or install must wait
  /// for.
  bool get isBusy => switch (this) {
    checking || downloading || verifying || installing || restarting => true,
    _ => false,
  };
}
