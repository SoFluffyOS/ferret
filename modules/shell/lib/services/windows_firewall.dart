import 'dart:io';

import 'package:core/core.dart';

/// Windows' own list of apps allowed through its firewall, where a
/// dismissed "allow access" prompt is put right.
abstract final class WindowsFirewall {
  /// Opens Control Panel straight on "Allowed apps".
  static const allowedAppsArguments = [
    '/name',
    'Microsoft.WindowsFirewall',
    '/page',
    'pageConfigureApps',
  ];

  static Future<void> openAllowedApps() async {
    try {
      await Process.start(
        'control.exe',
        allowedAppsArguments,
        mode: .detached,
      );
    } on Object catch (error) {
      printWarning('Could not open Windows Firewall', error);
    }
  }
}
