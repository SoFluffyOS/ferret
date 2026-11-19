import 'dart:io';

import 'package:ferret_actions/src/computer_action.dart';
import 'package:ferret_actions/src/linux_computer_actions.dart';
import 'package:ferret_actions/src/mac_computer_actions.dart';
import 'package:ferret_actions/src/unsupported_computer_actions.dart';
import 'package:ferret_actions/src/windows_computer_actions.dart';

/// Runs a program and waits for it, as `Process.run` does.
typedef RunProcess = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Sleep, restart, shut down and volume for the computer the app runs on.
abstract interface class ComputerActions {
  /// The actions of the platform the app runs on. Phones get none.
  factory ComputerActions.current() {
    if (Platform.isMacOS) {
      return MacComputerActions();
    }

    if (Platform.isWindows) {
      return const WindowsComputerActions();
    }

    if (Platform.isLinux) {
      return LinuxComputerActions();
    }

    return const UnsupportedComputerActions();
  }

  /// What this platform can do at all.
  Set<ComputerAction> get supported;

  /// Does [action] right away. False when it couldn't, such as when the
  /// system refused. Sleep, restart and shut down return once the system
  /// took the request, which is before it happens.
  Future<bool> run(ComputerAction action);
}
