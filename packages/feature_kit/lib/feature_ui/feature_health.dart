/// How a feature is doing with one device, shown under "What works" on the
/// device's page.
enum FeatureHealthState {
  /// Working: the last round trip succeeded.
  ok,

  /// Needs the user, such as a permission.
  needsAttention,

  /// Turned off, or the other device doesn't offer it.
  off,

  /// Tried and failed.
  failing,
}

class FeatureHealth {
  const FeatureHealth(
    this.state, {
    this.reason = '',
    this.help = '',
    this.onFix,
  });

  final FeatureHealthState state;

  /// One short fact next to the feature's name on the device's page, such as
  /// "Syncs by itself" or "Off on Pixel 9".
  final String reason;

  /// How to turn it on or get it working, shown behind "How?". Steps on the
  /// other device start with its name: "On Pixel 9: Ferret → Do more →
  /// Notifications".
  final String help;

  /// Fixes it from here, behind "Fix", such as opening the permission that
  /// was lost. Null when there is nothing this device can do.
  final void Function()? onFix;
}
