import 'package:flutter/foundation.dart';
import 'package:protocol/protocol.dart';

/// What to call a computer in a sentence: "this Mac", "this PC", "this
/// computer". The strings pick by [name].
enum ComputerKind {
  mac,
  windows,
  linux;

  /// The computer this app runs on.
  static ComputerKind get here => switch (defaultTargetPlatform) {
    .macOS => mac,
    .windows => windows,
    _ => linux,
  };

  /// The computer another device says it is.
  static ComputerKind of(Platform platform) => switch (platform) {
    .PLATFORM_MACOS => mac,
    .PLATFORM_WINDOWS => windows,
    _ => linux,
  };
}
