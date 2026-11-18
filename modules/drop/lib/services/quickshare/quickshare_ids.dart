/// How Quick Share senders appear among Drop's devices.
abstract final class QuickShareIds {
  static const _prefix = 'quickshare:';
  static const _label = 'Quick Share';

  /// The device id Drop uses for the sender of the session [sessionId].
  /// Senders carry no lasting identity, so each offer gets its own.
  static String deviceId(String sessionId) => '$_prefix$sessionId';

  static bool isQuickShare(String deviceId) => deviceId.startsWith(_prefix);

  /// The name shown for a Quick Share sender, always marked as such so it
  /// is never mistaken for a paired device. The protocol's name is the
  /// same in every language.
  static String label(String name) => '$name ($_label)';
}
