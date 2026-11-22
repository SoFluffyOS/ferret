import 'dart:io';

import 'package:path/path.dart' as p;

/// How this copy of Ferret was installed, which decides what an update
/// can do: install itself, or only say that it's out.
enum InstallKind {
  /// Ferret.app on a Mac: replaces itself from the release's DMG.
  macApp,

  /// Installed on Windows by Ferret's setup: runs the new setup silently.
  windowsSetup,

  /// The AppImage on Linux (the install script's
  /// `~/.local/opt/ferret/Ferret.AppImage`): replaced in place.
  linuxAppImage,

  /// The APK from GitHub on Android: handed to Android's installer.
  androidApk,

  /// A .deb, Flatpak or Snap: the system's package manager updates it.
  packageManager,

  /// Run from somewhere Ferret can't update, such as a build or an
  /// unpacked folder: an update only links to the download page.
  manual,

  /// An app store updates it (App Store, Play, F-Droid, Microsoft Store),
  /// so Ferret never checks.
  store;

  /// Whether Ferret can install an update itself.
  bool get installsItself => switch (this) {
    macApp || windowsSetup || linuxAppImage || androidApk => true,
    packageManager || manual || store => false,
  };

  /// Whether Ferret looks for updates at all.
  bool get checks => this != store;

  /// The stores that update an Android app themselves, by installer
  /// package name.
  static const androidStores = {
    'com.android.vending',
    'org.fdroid.fdroid',
    'org.fdroid.basic',
    'com.aurora.store',
    'com.sec.android.app.samsungapps',
    'com.amazon.venezia',
    'com.huawei.appmarket',
    'com.xiaomi.market',
  };

  /// Works out this copy's kind. [androidInstaller] is the package that
  /// installed Ferret on Android (null for a file or `adb`).
  static Future<InstallKind> detect({
    required String operatingSystem,
    required String executable,
    required Map<String, String> environment,
    required bool isReleaseBuild,
    String? androidInstaller,
    Future<bool> Function(String path)? exists,
  }) async {
    final fileExists = exists ?? (path) => FileSystemEntity.isFile(path);
    switch (operatingSystem) {
      case 'ios':
        return store;
      case 'android':
        if (androidStores.contains(androidInstaller)) {
          return store;
        }

        return androidApk;
      case 'macos':
        final bundle = p.dirname(p.dirname(p.dirname(executable)));
        if (!bundle.endsWith('.app') || !isReleaseBuild) {
          return manual;
        }

        if (await fileExists(
          p.join(bundle, 'Contents', '_MASReceipt', 'receipt'),
        )) {
          return store;
        }

        return macApp;
      case 'windows':
        if (executable.toLowerCase().contains(r'\windowsapps\')) {
          return store;
        }

        final uninstaller = p.windows.join(
          p.windows.dirname(executable),
          'unins000.exe',
        );
        if (isReleaseBuild && await fileExists(uninstaller)) {
          return windowsSetup;
        }

        return manual;
      case 'linux':
        if (environment.containsKey('FLATPAK_ID') ||
            environment.containsKey('SNAP') ||
            await fileExists('/.flatpak-info')) {
          return packageManager;
        }

        if (environment['APPIMAGE'] case final appImage?
            when appImage.isNotEmpty && isReleaseBuild) {
          return linuxAppImage;
        }

        if (executable.startsWith('/usr/') || executable.startsWith('/opt/')) {
          return packageManager;
        }

        return manual;
    }

    return manual;
  }
}
