import 'package:ferret_mirror_scrcpy/src/download/download.dart';

/// Google's Android SDK Platform-Tools (adb), the stable release listed in
/// `dl.google.com/android/repository/repository2-3.xml`.
///
/// Google publishes only SHA-1 there. The SHA-256 values below were
/// computed from downloads whose SHA-1 matched that list.
abstract final class PlatformToolsRelease {
  static const String version = '37.0.1';

  static const String _base =
      'https://dl.google.com/android/repository/platform-tools_r$version';

  static const PinnedFile macos = PinnedFile(
    url: '$_base-darwin.zip',
    sha256: 'ee39ad5967e95c2a07f04dbcbde96b1a0c916ba376096db5d2f498b7727a5d1d',
    fileName: 'platform-tools_r$version-darwin.zip',
  );

  static const PinnedFile linux = PinnedFile(
    url: '$_base-linux.zip',
    sha256: 'd230f13842f60f782a8645f9c813f8f845bf36089ea7289f28c48f17979313f1',
    fileName: 'platform-tools_r$version-linux.zip',
  );

  static const PinnedFile windows = PinnedFile(
    url: '$_base-win.zip',
    sha256: '45f4d63113e895ebde0c90f194099a4676b6ac653bd28d54314a9e022bbc1a99',
    fileName: 'platform-tools_r$version-win.zip',
  );

  /// The download for [operatingSystem] (`Platform.operatingSystem`), or
  /// null where Google has none.
  static PinnedFile? forSystem(String operatingSystem) {
    return switch (operatingSystem) {
      'macos' => macos,
      'linux' => linux,
      'windows' => windows,
      _ => null,
    };
  }
}
