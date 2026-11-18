/// How LocalSend devices appear among Drop's devices.
abstract final class LocalSendIds {
  static const _prefix = 'localsend:';
  static const _label = 'LocalSend';

  /// The device id Drop uses for the LocalSend device with [fingerprint].
  static String deviceId(String fingerprint) =>
      '$_prefix${fingerprint.toLowerCase()}';

  static bool isLocalSend(String deviceId) => deviceId.startsWith(_prefix);

  /// The name shown for a LocalSend device, always marked as such so it
  /// is never mistaken for a paired device. The protocol's name is the
  /// same in every language.
  static String label(String alias) => '$alias ($_label)';
}
