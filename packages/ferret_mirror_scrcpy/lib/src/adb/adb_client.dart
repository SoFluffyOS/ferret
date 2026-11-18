import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ferret_mirror_scrcpy/src/adb/adb_bridge.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_connection.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_device.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_exception.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_result.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_shell.dart';

/// Talks to Android devices by running the `adb` program. Its first
/// command starts adb's background server when none is running.
class AdbClient implements AdbBridge {
  AdbClient(this.executable);

  static const Duration _commandTimeout = Duration(seconds: 20);
  static final RegExp _port = RegExp(r'^\d+$', multiLine: true);

  /// The path of the adb program.
  final String executable;

  final Map<String, int> _forwardedPorts = {};

  /// Whether the program can be started at all. Inside the macOS App
  /// Sandbox it can't, wherever the file is.
  Future<bool> canRun() async {
    try {
      final result = await Process.run(executable, ['version']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  @override
  Future<List<AdbDevice>> devices() async =>
      AdbDevice.parseList(await _run(['devices', '-l']));

  @override
  Future<void> push(String serial, File file, String devicePath) async {
    await _run(['-s', serial, 'push', file.path, devicePath]);
  }

  @override
  Future<String> shell(String serial, List<String> command) =>
      _run(['-s', serial, 'shell', ...command]);

  @override
  Future<AdbShell> startShell(String serial, List<String> command) async {
    final Process process;
    try {
      process = await Process.start(executable, [
        '-s',
        serial,
        'shell',
        ...command,
      ]);
    } on ProcessException catch (error) {
      throw AdbException('Could not run adb: ${error.message}');
    }

    final lines = StreamController<String>();
    var openStreams = 2;
    void closeOne() {
      openStreams--;
      if (openStreams == 0) {
        unawaited(lines.close());
      }
    }

    for (final output in [process.stdout, process.stderr]) {
      output
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen(lines.add, onError: (Object _) {}, onDone: closeOne);
    }

    return AdbShell(
      lines: lines.stream,
      done: process.exitCode.then<void>((_) {}),
      kill: process.kill,
    );
  }

  /// Through a port adb forwards to the device, opened on the first call.
  /// Such a port takes connections even while nothing listens on the
  /// device, and then closes them.
  @override
  Future<AdbConnection?> open(String serial, String socketName) async {
    final key = '$serial $socketName';
    final port = _forwardedPorts[key] ??= await _forward(serial, socketName);
    try {
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
      return SocketAdbConnection(socket);
    } on SocketException {
      return null;
    }
  }

  @override
  Future<void> release(String serial, String socketName) async {
    final port = _forwardedPorts.remove('$serial $socketName');
    if (port == null) {
      return;
    }

    await _run(['-s', serial, 'forward', '--remove', 'tcp:$port']);
  }

  @override
  Future<AdbResult> pair(String address, String code) async {
    final output = await _runLenient(['pair', address, code]);
    return AdbResult(
      succeeded: output.contains('Successfully paired'),
      message: output,
    );
  }

  @override
  Future<AdbResult> connect(String address) async {
    final output = await _runLenient(['connect', address]);
    final isConnected =
        output.contains('connected to') && !output.contains('failed');
    return AdbResult(succeeded: isConnected, message: output);
  }

  @override
  Future<void> disconnect(String address) async {
    await _runLenient(['disconnect', address]);
  }

  Future<int> _forward(String serial, String socketName) async {
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
