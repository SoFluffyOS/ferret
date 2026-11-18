import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A stand-in for adb's background server: it speaks just enough of the
/// host protocol for the tests, on a port of its own.
class FakeAdbServer {
  FakeAdbServer._(this._server) {
    _server.listen((socket) => _FakeAdbSession(this, socket));
  }

  static Future<FakeAdbServer> start() async =>
      FakeAdbServer._(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));

  final ServerSocket _server;

  String deviceList = '';
  final List<String> requests = [];
  final Map<String, Uint8List> pushed = {};
  String? pushFailure;

  int get port => _server.port;

  Future<void> stop() => _server.close();
}

enum _Mode { requests, sync, raw }

class _FakeAdbSession {
  _FakeAdbSession(this._server, this._socket) {
    _socket.done.ignore();
    _socket.listen(_onData, onError: (Object _) {});
  }

  final FakeAdbServer _server;
  final Socket _socket;
  final List<int> _buffer = [];
  final BytesBuilder _file = .new();
  _Mode _mode = .requests;
  String _pushPath = '';

  void _onData(Uint8List chunk) {
    _buffer.addAll(chunk);
    while (_step()) {}
  }

  bool _step() {
    return switch (_mode) {
      .requests => _readRequest(),
      .sync => _readSync(),
      .raw => _echo(),
    };
  }

  bool _readRequest() {
    if (_buffer.length < 4) {
      return false;
    }

    final length = int.parse(ascii.decode(_buffer.sublist(0, 4)), radix: 16);
    if (_buffer.length < 4 + length) {
      return false;
    }

    final request = utf8.decode(_buffer.sublist(4, 4 + length));
    _buffer.removeRange(0, 4 + length);
    _server.requests.add(request);
    _answer(request);
    return true;
  }

  void _answer(String request) {
    switch (request) {
      case 'host:version':
        _okay(message: '0029');
      case 'host:devices-l':
        _okay(message: _server.deviceList);
      case 'host:transport:GOOD' || 'localabstract:there':
        _okay();
        _afterOkay(request);
      case 'sync:':
        _okay();
        _mode = .sync;
      case 'shell:echo hi':
        _okay();
        _socket.write('hi\n');
        _socket.destroy();
      case 'shell:two lines':
        _okay();
        _socket.write('first\nsecond\n');
        _socket.destroy();
      case final pair when pair.startsWith('host:pair:'):
        _okay(message: 'Successfully paired to ${pair.substring(17)}');
      case final connect when connect.startsWith('host:connect:'):
        _okay(message: 'connected to ${connect.substring(13)}');
      default:
        _fail('unknown: $request');
    }
  }

  void _afterOkay(String request) {
    if (request != 'localabstract:there') {
      return;
    }

    _mode = .raw;
    _socket.add([0]);
  }

  bool _readSync() {
    if (_buffer.length < 8) {
      return false;
    }

    final id = ascii.decode(_buffer.sublist(0, 4));
    final value = ByteData.sublistView(
      Uint8List.fromList(_buffer.sublist(4, 8)),
    ).getUint32(0, .little);
    if (id == 'DONE') {
      _buffer.removeRange(0, 8);
      _finishPush();
      return true;
    }

    if (_buffer.length < 8 + value) {
      return false;
    }

    final payload = _buffer.sublist(8, 8 + value);
    _buffer.removeRange(0, 8 + value);
    if (id == 'SEND') {
      _pushPath = utf8.decode(payload);
    }
    if (id == 'DATA') {
      _file.add(payload);
    }

    return true;
  }

  void _finishPush() {
    if (_server.pushFailure case final reason?) {
      final text = utf8.encode(reason);
      final length = ByteData(4)..setUint32(0, text.length, .little);
      _socket.add([...ascii.encode('FAIL'), ...length.buffer.asUint8List()]);
      _socket.add(text);
      return;
    }

    _server.pushed[_pushPath] = _file.takeBytes();
    _socket.add([...ascii.encode('OKAY'), 0, 0, 0, 0]);
  }

  bool _echo() {
    if (_buffer.isEmpty) {
      return false;
    }

    _socket.add(List.of(_buffer));
    _buffer.clear();
    return false;
  }

  void _okay({String? message}) {
    _socket.write('OKAY');
    if (message != null) {
      _socket.write(message.length.toRadixString(16).padLeft(4, '0'));
      _socket.write(message);
    }
  }

  void _fail(String reason) {
    _socket.write('FAIL${reason.length.toRadixString(16).padLeft(4, '0')}');
    _socket.write(reason);
  }
}
