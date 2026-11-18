/// The scrcpy release this package speaks, and ships the server of. The
/// protocol is internal to scrcpy and changes between versions, so the
/// server and everything in `protocol/` move together: bump this only
/// after checking them against the new version's `doc/develop.md`,
/// `Options.java` and `control_msg.c`.
abstract final class ScrcpyRelease {
  static const String version = '5.0.1';

  static const String serverFileName = 'scrcpy-server-v$version';

  /// Where Flutter keeps the server's file, as released by scrcpy.
  static const String serverAsset =
      'packages/ferret_mirror_scrcpy/assets/$serverFileName';

  /// SHA-256 from the release's own `SHA256SUMS.txt`, lowercase hex.
  static const String serverSha256 =
      '764eb6f79811d5211fe9df341120882ba9994c7a61b897d7bf3fb662e53bc536';
}
