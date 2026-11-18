import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/src/adb/adb_bridge.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_connection.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_device.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_exception.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_host_socket.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_result.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_shell.dart';

/// Talks to adb's background server over its socket on this computer (the
/// "host protocol", port 5037), without running the `adb` program.
///
/// It needs that server to be running already: Android Studio, a terminal
/// or the `adb` program started it. In return it works where a program
/// can't be run or can't reach USB, such as inside the macOS App Sandbox.
class AdbHostClient implements AdbBridge {
  AdbHostClient({this.port = defaultPort});

  static const int defaultPort = 5037;

  /// `S_IFREG | 0644`: a plain file its owner can write.
  static const int _fileMode = 33188;
  static const int _syncChunkSize = 64 * 1024;

  final int port;

  /// Whether an adb server answers on [port].
  Future<bool> isRunning() async {
    try {
      final socket = await AdbHostSocket.connect(port);
      await socket.request('host:version');
      socket.close();
      return true;
    } on SocketException {
      return false;
    } on AdbException {
      return false;
    }
  }

  @override
  Future<List<AdbDevice>> devices() => _ask('host:devices-l').then(
    (list) => AdbDevice.parseList(list),
  );

  @override
  Future<void> push(String serial, File file, String devicePath) async {
    final socket = await _transport(serial);
    try {
      await socket.request('sync:');
      _sendSync(socket, 'SEND', utf8.encode('$devicePath,$_fileMode'));

      final bytes = await file.readAsBytes();
      for (var start = 0; start < bytes.length; start += _syncChunkSize) {
        final end = (start + _syncChunkSize).clamp(0, bytes.length);
        _sendSync(socket, 'DATA', Uint8List.sublistView(bytes, start, end));
      }
      final modified = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      socket.add([...ascii.encode('DONE'), ..._littleEndian(modified)]);

      await _readSyncStatus(socket);
    } finally {
      socket.close();
    }
  }

  @override
  Future<String> shell(String serial, List<String> command) async {
    final socket = await _transport(serial);
    try {
      await socket.request('shell:${command.join(' ')}');
      return utf8.decode(await socket.readToEnd(), allowMalformed: true).trim();
    } finally {
      socket.close();
    }
  }

  @override
  Future<AdbShell> startShell(String serial, List<String> command) async {
    final socket = await _transport(serial);
    try {
      await socket.request('shell:${command.join(' ')}');
    } on AdbException {
      socket.close();
      rethrow;
    }

    final done = Completer<void>();
    final lines = socket.input
        .cast<List<int>>()
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .transform(
          StreamTransformer<String, String>.fromHandlers(
            handleDone: (sink) {
              done.complete();
              sink.close();
            },
          ),
        );

    return AdbShell(lines: lines, done: done.future, kill: socket.close);
  }

  /// Straight to the device's socket through adb's server: no port is
  /// opened on this computer, and nothing is left to take back.
  @override
  Future<AdbConnection?> open(String serial, String socketName) async {
    final AdbHostSocket socket;
    try {
      socket = await _transport(serial);
    } on AdbException {
      return null;
    }

    try {
      await socket.request('localabstract:$socketName');
      return socket;
    } on AdbException {
      socket.close();
      return null;
    }
  }

  @override
  Future<void> release(String serial, String socketName) async {}

  @override
  Future<AdbResult> pair(String address, String code) async {
    final answer = await _ask('host:pair:$code:$address');
    return AdbResult(
      succeeded: answer.contains('Successfully paired'),
      message: answer,
    );
  }

  @override
  Future<AdbResult> connect(String address) async {
    final answer = await _ask('host:connect:$address');
    final isConnected =
        answer.contains('connected to') && !answer.contains('failed');
    return AdbResult(succeeded: isConnected, message: answer);
  }

  @override
  Future<void> disconnect(String address) async {
    await _ask('host:disconnect:$address');
  }

  /// One request to the server itself, answered with one message.
  Future<String> _ask(String service) async {
    final socket = await _connect();
    try {
      await socket.request(service);
      return (await socket.readMessage()).trim();
    } finally {
      socket.close();
    }
  }

  Future<AdbHostSocket> _transport(String serial) async {
    final socket = await _connect();
    try {
      await socket.request('host:transport:$serial');
      return socket;
    } on AdbException {
      socket.close();
      rethrow;
    }
  }

  Future<AdbHostSocket> _connect() async {
    try {
      return await AdbHostSocket.connect(port);
    } on SocketException catch (error) {
      throw AdbException('No adb server on port $port: ${error.message}');
    }
  }

  static void _sendSync(AdbHostSocket socket, String id, List<int> payload) {
    socket
      ..add([...ascii.encode(id), ..._littleEndian(payload.length)])
      ..add(payload);
  }

  static Future<void> _readSyncStatus(AdbHostSocket socket) async {
    final status = await socket.read(8);
    final id = ascii.decode(status.sublist(0, 4), allowInvalid: true);
    if (id == 'OKAY') {
      return;
    }

    final length = ByteData.sublistView(status).getUint32(4, .little);
    final reason = utf8.decode(await socket.read(length), allowMalformed: true);
    throw AdbException('Push failed: $reason');
  }

  static Uint8List _littleEndian(int value) {
    final bytes = ByteData(4)..setUint32(0, value, .little);
    return bytes.buffer.asUint8List();
  }
}
