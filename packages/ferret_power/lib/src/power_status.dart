/// Where the Shizuku setup stands. Each value is the next thing to fix.
enum ShizukuStatus { notInstalled, notRunning, notAuthorized, ready }

/// Whether this phone is rooted, and whether `su` said yes to Ferret.
enum RootStatus { notFound, found, granted }

/// The app that manages root, when Ferret can tell.
enum RootManager { none, magisk, kernelSu, aPatch, unknown }

/// What this device offers right now. Reading it never asks the user for
/// anything.
class PowerStatus {
  const PowerStatus({
    this.supported = false,
    this.shizuku = .notInstalled,
    this.root = .notFound,
    this.rootManager = .none,
    this.notificationAccess = false,
    this.messagesAndCalls = false,
    this.batteryUnrestricted = false,
  });

  /// Every platform but Android: there are no tiers to climb.
  static const unsupported = PowerStatus();

  /// False on every platform but Android.
  final bool supported;
  final ShizukuStatus shizuku;
  final RootStatus root;
  final RootManager rootManager;

  /// Ferret's notification listener is turned on.
  final bool notificationAccess;

  /// The SMS or the phone permission is granted.
  final bool messagesAndCalls;

  /// Ferret is exempt from battery optimisation.
  final bool batteryUnrestricted;

  @override
  bool operator ==(Object other) =>
      other is PowerStatus &&
      other.supported == supported &&
      other.shizuku == shizuku &&
      other.root == root &&
      other.rootManager == rootManager &&
      other.notificationAccess == notificationAccess &&
      other.messagesAndCalls == messagesAndCalls &&
      other.batteryUnrestricted == batteryUnrestricted;

  @override
  int get hashCode => Object.hash(
    supported,
    shizuku,
    root,
    rootManager,
    notificationAccess,
    messagesAndCalls,
    batteryUnrestricted,
  );
}
