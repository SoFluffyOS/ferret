import 'package:ferret_mirror_scrcpy/src/download/download.dart';

/// The scrcpy release this package speaks. The protocol is internal to
/// scrcpy and changes between versions, so the server and everything in
/// `protocol/` move together: bump this only after checking them against
/// the new version's `doc/develop.md`, `Options.java` and `control_msg.c`.
abstract final class ScrcpyRelease {
  static const String version = '5.0.1';

  /// SHA-256 from the release's own `SHA256SUMS.txt`.
  static const PinnedFile server = PinnedFile(
    url:
        'https://github.com/Genymobile/scrcpy/releases/download/v$version/scrcpy-server-v$version',
    sha256: '764eb6f79811d5211fe9df341120882ba9994c7a61b897d7bf3fb662e53bc536',
    fileName: 'scrcpy-server-v$version',
  );
}
