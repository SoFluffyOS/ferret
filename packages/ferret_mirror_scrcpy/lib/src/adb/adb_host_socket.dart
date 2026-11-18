import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/src/adb/adb_connection.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_exception.dart';
import 'package:ferret_mirror_scrcpy/src/protocol/protocol.dart';

/// One connection to adb's server, speaking its host protocol: a request
/// is 4 hex digits of length and the text, the answer starts with `OKAY`
/// or `FAIL`. After a `host:transport` request the same connection talks
/// to the device.
class AdbHostSocket implements AdbConnection {
  AdbHostSocket._(this._socket) {
    _socket.setOption(.tcpNoDelay, true);
    _socket.done.ignore();
    _socket.listen(_onData, onError: (Object _) => _onDone(), onDone: _onDone);
  }

  static const Duration _connectTimeout = Duration(seconds: 2);

  final Socket _socket;
  final ByteQueue _queue = .new();
  final StreamController<Uint8List> _rest = .new();
  Completer<void>? _arrival;
  bool _isDetached = false;
  bool _isClosed = false;

  /// Throws a [SocketException] when no adb server listens on [port].
  static Future<AdbHostSocket> connect(int port) async {
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      port,
      timeout: _connectTimeout,
    );
    return AdbHostSocket._(socket);
  }

  /// Everything from here on, raw: for after the last request, when the
  /// connection belongs to a service on the device.
  @override
  Stream<Uint8List> get input {
    if (!_isDetached) {
      _isDetached = true;
      _rest.add(_queue.takeAll());
      if (_isClosed) {
        unawaited(_rest.close());
      }
    }

    return _rest.stream;
  }

  @override
  void add(List<int> bytes) {
    try {
      _socket.add(bytes);
    } on StateError {
      // Closing: whoever reads sees the end.
    }
  }

  @override
  void close() => _socket.destroy();

  /// Sends [service] and waits for `OKAY`. Throws an [AdbException] with
  /// adb's reason on `FAIL`.
  Future<void> request(String service) async {
    final text = utf8.encode(service);
    add(ascii.encode(text.length.toRadixString(16).padLeft(4, '0')));
    add(text);

    final status = ascii.decode(await read(4), allowInvalid: true);
    if (status == 'OKAY') {
      return;
    }

    if (status == 'FAIL') {
      throw AdbException(await readMessage());
    }

    throw AdbException('adb answered "$status" to $service');
  }

  /// One length-prefixed text, as adb sends its answers.
  Future<String> readMessage() async {
    final length = int.tryParse(ascii.decode(await read(4)), radix: 16);
    if (length == null) {
      throw const AdbException('adb sent a message without a length');
    }

    return utf8.decode(await read(length), allowMalformed: true);
  }

  /// The next [count] bytes. Throws an [AdbException] when the connection
  /// ends before they came.
  Future<Uint8List> read(int count) async {
    while (true) {
      if (_queue.take(count) case final bytes?) {
        return bytes;
      }

      if (_isClosed) {
        throw const AdbException('adb closed the connection');
      }

      final arrival = Completer<void>();
      _arrival = arrival;
      await arrival.future;
    }
  }

  /// Everything until the other side closes.
  Future<Uint8List> readToEnd() async {
    while (!_isClosed) {
      final arrival = Completer<void>();
      _arrival = arrival;
      await arrival.future;
    }

    return _queue.takeAll();
  }

  void _onData(Uint8List chunk) {
    if (_isDetached) {
      _rest.add(chunk);
      return;
    }

    _queue.add(chunk);
    _wake();
  }

  void _onDone() {
    _isClosed = true;
    _wake();
    if (_isDetached) {
      unawaited(_rest.close());
    }
  }

  void _wake() {
    final arrival = _arrival;
    _arrival = null;
    arrival?.complete();
  }
}
