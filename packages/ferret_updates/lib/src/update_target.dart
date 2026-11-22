import 'dart:ffi';

import 'package:ferret_updates/src/update_asset.dart';
import 'package:ferret_updates/src/update_release.dart';

/// The system a build runs on, which picks its file out of a release by
/// the stable names the download page uses too.
enum UpdateTarget {
  mac('Ferret-mac.dmg'),
  windowsX64('Ferret-windows-x64-setup.exe'),
  windowsArm64('Ferret-windows-arm64-setup.exe'),
  linuxX64('Ferret-linux-x86_64.AppImage'),
  linuxArm64('Ferret-linux-aarch64.AppImage'),
  android('Ferret-android.apk');

  const UpdateTarget(this.assetName);

  /// The file's name in every release.
  final String assetName;

  /// The list of every file's SHA-256 in a release.
  static const checksumsName = 'SHA256SUMS';

  /// This build's target, or null where Ferret doesn't update itself.
  static UpdateTarget? get current => forAbi(Abi.current());

  static UpdateTarget? forAbi(Abi abi) => switch (abi) {
    .macosArm64 || .macosX64 => mac,
    .windowsX64 => windowsX64,
    .windowsArm64 => windowsArm64,
    .linuxX64 => linuxX64,
    .linuxArm64 => linuxArm64,
    .androidArm64 || .androidArm || .androidX64 || .androidIA32 => android,
    _ => null,
  };

  UpdateAsset? assetIn(UpdateRelease release) => release.assetNamed(assetName);
}
