/// Finds a newer Ferret in its GitHub releases, downloads it over HTTPS,
/// checks it against the release's SHA256SUMS and the platform's signature,
/// and installs it: a DMG on macOS, the setup on Windows, the AppImage on
/// Linux and the APK through PackageInstaller on Android.
library;

export 'package:ferret_updates/src/android_update_installer.dart';
export 'package:ferret_updates/src/checksums.dart';
export 'package:ferret_updates/src/install_kind.dart';
export 'package:ferret_updates/src/linux_update_installer.dart';
export 'package:ferret_updates/src/macos_update_installer.dart';
export 'package:ferret_updates/src/release_source.dart';
export 'package:ferret_updates/src/release_version.dart';
export 'package:ferret_updates/src/update_asset.dart';
export 'package:ferret_updates/src/update_http.dart';
export 'package:ferret_updates/src/update_installer.dart';
export 'package:ferret_updates/src/update_release.dart';
export 'package:ferret_updates/src/update_target.dart';
export 'package:ferret_updates/src/windows_update_installer.dart';
