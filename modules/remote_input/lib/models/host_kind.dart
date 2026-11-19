import 'package:flutter/foundation.dart';

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
}
