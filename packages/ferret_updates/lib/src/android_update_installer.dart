import 'dart:io';

import 'package:ferret_updates/src/update_installer.dart';
import 'package:flutter/services.dart';

/// Hands a downloaded APK to Android's PackageInstaller (a session), which
/// shows its own prompt and installs it only when it is signed with the
/// same key as the Ferret already on the phone.
///
/// Android first asks the person to let Ferret install apps ("Install
/// unknown apps"); [install] says so with [InstallOutcome.needsPermission]
/// and [openPermissionSettings] opens that switch.
class AndroidUpdateInstaller implements UpdateInstaller {
  const AndroidUpdateInstaller();

  static const _channel = MethodChannel('io.sofluffy.ferret_updates');

  /// The package that installed Ferret, such as `com.android.vending`, or
  /// null for a file opened by hand or `adb`.
  static Future<String?> installerPackage() async {
    try {
      return await _channel.invokeMethod<String>('installerPackage');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Whether Android lets Ferret install apps right now.
  Future<bool> canInstall() async {
    try {
      return await _channel.invokeMethod<bool>('canInstall') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens Android's "Install unknown apps" switch for Ferret.
  Future<void> openPermissionSettings() =>
      _channel.invokeMethod<void>('openPermissionSettings');

  @override
  Future<InstallOutcome> install(File file) async {
    if (!await canInstall()) {
      return .needsPermission;
    }

    await _channel.invokeMethod<void>('install', {'path': file.path});
    return .handedToSystem;
  }
}
