import 'dart:io';

import 'package:ferret_actions/src/linux_input_idle.dart';
import 'package:ferret_actions/src/mac_input_idle.dart';
import 'package:ferret_actions/src/unsupported_input_idle.dart';
import 'package:ferret_actions/src/windows_input_idle.dart';

/// How long nobody has touched this computer's keyboard, mouse or
/// trackpad.
abstract interface class InputIdle {
  /// The reader for the platform the app runs on.
  factory InputIdle.current() {
    if (Platform.isMacOS) {
      return const MacInputIdle();
    }

    if (Platform.isWindows) {
      return const WindowsInputIdle();
    }

    if (Platform.isLinux) {
      return LinuxInputIdle();
    }

    return const UnsupportedInputIdle();
  }

  /// Time since the last input, or null when the system won't say.
  Future<Duration?> idleTime();
}
