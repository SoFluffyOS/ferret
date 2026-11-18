import 'dart:io';

import 'package:ferret_remote_input/src/injector_status.dart';
import 'package:ferret_remote_input/src/input_action.dart';
import 'package:ferret_remote_input/src/linux/linux.dart';
import 'package:ferret_remote_input/src/native_injector.dart';
import 'package:ferret_remote_input/src/unsupported_injector.dart';

/// Moves the pointer, clicks, scrolls and types on this computer, as if
/// someone used its own mouse and keyboard.
abstract interface class InputInjector {
  /// The implementation for the platform the app runs on.
  factory InputInjector.current() {
    if (Platform.isMacOS) {
      return NativeInjector.macos();
    }

    if (Platform.isWindows) {
      return NativeInjector.windows();
    }

    if (Platform.isLinux) {
      return LinuxInjector();
    }

    return UnsupportedInjector();
  }

  /// Whether this platform can inject input at all, without asking it.
  static bool get isSupportedPlatform =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  /// Checks again whether input can be injected right now.
  Future<InjectorStatus> status();

  /// Asks the person for access, such as the macOS Accessibility prompt.
  Future<InjectorStatus> requestAccess();

  /// Opens the system page where people allow access.
  Future<void> openAccessSettings();

  /// Performs [actions] in order.
  Future<void> inject(List<InputAction> actions);

  /// Lets go of every button and key still held down.
  Future<void> releaseAll();

  Future<void> dispose();
}
