import 'dart:io';

/// Which native side [FerretSystem] talks to.
enum SystemPlatform {
  /// The full plugin: service, tile, battery, network and wake events.
  android,

  /// Network and wake events from the plugin.
  macos,

  /// Linux and Windows: network and wake events come from polling in Dart.
  desktop,

  /// No native side, such as iOS, where the app is suspended in the
  /// background and reconnects when it comes back.
  none;

  static SystemPlatform get current {
    if (Platform.isAndroid) {
      return android;
    }

    if (Platform.isMacOS) {
      return macos;
    }

    if (Platform.isLinux || Platform.isWindows) {
      return desktop;
    }

    return none;
  }
}
