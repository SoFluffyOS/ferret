import 'package:flutter/foundation.dart';
import 'package:protocol/protocol.dart' show Platform;

/// What kind of computer is controlled, for the names of its modifier keys.
enum HostKind {
  mac,
  windows,
  linux;

  /// The computer this app runs on.
  static HostKind get here => switch (defaultTargetPlatform) {
    .macOS => mac,
    .windows => windows,
    _ => linux,
  };

  /// The kind of computer [platform] is, or null when it isn't one Ferret
  /// controls, such as a phone or a device that never said.
  static HostKind? of(Platform? platform) => switch (platform) {
    .PLATFORM_MACOS => mac,
    .PLATFORM_WINDOWS => windows,
    .PLATFORM_LINUX => linux,
    _ => null,
  };
}
