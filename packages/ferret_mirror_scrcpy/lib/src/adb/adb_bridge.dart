import 'dart:io';

import 'package:ferret_mirror_scrcpy/src/adb/adb_connection.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_device.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_result.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_shell.dart';

/// What this package needs from adb, whichever way adb is reached: its
/// background server on this computer, or the `adb` program. Commands
/// throw an `AdbException` when adb says no.
abstract interface class AdbBridge {
  /// Every device adb knows, whatever its state.
  Future<List<AdbDevice>> devices();

  /// Copies [file] to [devicePath] on the device.
  Future<void> push(String serial, File file, String devicePath);

  /// Runs [command] on the device and returns what it printed.
  Future<String> shell(String serial, List<String> command);

  /// Starts [command] on the device and leaves it running.
  Future<AdbShell> startShell(String serial, List<String> command);

  /// Connects to the abstract socket [socketName] on the device. Null when
  /// that couldn't be done. A connection may also open with nothing
  /// listening yet, and then closes without a byte.
  Future<AdbConnection?> open(String serial, String socketName);

  /// Takes back whatever [open] set up on this computer for [socketName].
  Future<void> release(String serial, String socketName);

  /// Pairs with a device showing "Pair device with pairing code" (Android
  /// 11 and later). [address] is the `host:port` on that screen, which is
  /// not the one to [connect] to.
  Future<AdbResult> pair(String address, String code);

  /// Connects to a device over the network, at the `host:port` on its
  /// Wireless debugging screen.
  Future<AdbResult> connect(String address);

  Future<void> disconnect(String address);
}
