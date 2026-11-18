import 'dart:async';
import 'dart:io';

import 'package:ferret_mirror_scrcpy/src/adb/adb_device.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_exception.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_result.dart';

/// Talks to Android devices by running the `adb` program.
class AdbClient {
  AdbClient(this.executable);

  static const Duration _commandTimeout = Duration(seconds: 20);
  static final RegExp _port = RegExp(r'^\d+$', multiLine: true);

  /// The path of the adb program.
  final String executable;

  /// Every device adb knows, whatever its state. Starts adb's own
  /// background server when it isn't running.
  Future<List<AdbDevice>> devices() async =>
      AdbDevice.parseList(await _run(['devices', '-l']));

  Future<void> push(String serial, String localPath, String devicePath) async {
    await _run(['-s', serial, 'push', localPath, devicePath]);
  }

  /// Opens a port on this computer that leads to the abstract socket
  /// [socketName] on the device, and returns the port adb picked.
  Future<int> forward(String serial, String socketName) async {
    final output = await _run([
      '-s',
      serial,
      'forward',
      'tcp:0',
      'localabstract:$socketName',
    ]);
    final port = int.tryParse(_port.stringMatch(output) ?? '');
    if (port == null) {
      throw AdbException('adb forward gave no port: $output');
    }

    return port;
  }

  Future<void> removeForward(String serial, int port) async {
    await _run(['-s', serial, 'forward', '--remove', 'tcp:$port']);
  }

  /// Runs [command] on the device and returns what it printed.
  Future<String> shell(String serial, List<String> command) =>
      _run(['-s', serial, 'shell', ...command]);

  /// Starts [command] on the device and leaves it running: it ends with
  /// the returned process.
  Future<Process> startShell(String serial, List<String> command) =>
      Process.start(executable, ['-s', serial, 'shell', ...command]);

  /// Pairs with a device showing "Pair device with pairing code" (Android
  /// 11 and later). [address] is the `host:port` on that screen, which is
  /// not the one to [connect] to.
  Future<AdbResult> pair(String address, String code) async {
    final output = await _runLenient(['pair', address, code]);
    return AdbResult(
      succeeded: output.contains('Successfully paired'),
      message: output,
    );
  }

  /// Connects to a device over the network, at the `host:port` on its
  /// Wireless debugging screen.
  Future<AdbResult> connect(String address) async {
    final output = await _runLenient(['connect', address]);
    final isConnected =
        output.contains('connected to') && !output.contains('failed');
    return AdbResult(succeeded: isConnected, message: output);
  }

  Future<void> disconnect(String address) async {
    await _runLenient(['disconnect', address]);
  }

  Future<String> _run(List<String> arguments) async {
    final result = await _result(arguments);
    if (result.exitCode != 0) {
      throw AdbException(
        'adb ${arguments.first} exited with ${result.exitCode}: '
        '${_text(result.stderr)}',
      );
    }

    return _text(result.stdout);
  }

  /// For commands that say how they went in words, on either stream, with
  /// exit codes that changed between adb versions.
  Future<String> _runLenient(List<String> arguments) async {
    final result = await _result(arguments);
    return '${_text(result.stdout)}\n${_text(result.stderr)}'.trim();
  }

  Future<ProcessResult> _result(List<String> arguments) async {
    try {
      return await Process.run(executable, arguments).timeout(_commandTimeout);
    } on TimeoutException {
      throw AdbException('adb ${arguments.first} took too long');
    } on ProcessException catch (error) {
      throw AdbException('Could not run adb: ${error.message}');
    }
  }

  static String _text(Object? output) => '$output'.trim();
}
