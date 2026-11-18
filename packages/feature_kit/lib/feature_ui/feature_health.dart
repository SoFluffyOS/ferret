/// How a feature is doing with one device, shown as a chip on the device card.
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
  const FeatureHealth(this.state, {this.reason = ''});

  final FeatureHealthState state;

  /// One short sentence, shown when the chip is tapped, such as "Notification
  /// access is off on Pixel".
  final String reason;
}
