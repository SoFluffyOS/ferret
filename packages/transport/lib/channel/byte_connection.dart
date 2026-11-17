import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// A reliable, ordered byte pipe, such as a TCP socket. Bluetooth or a relay
/// can implement it too, so the secure channel works over any of them.
abstract interface class ByteConnection {
  Stream<Uint8List> get input;

  void add(List<int> bytes);

  Future<void> flush();

  Future<void> close();

  /// Where the other side is, for logs and reconnecting, such as
  /// `192.168.1.20:47640`.
  String get remoteAddress;
}

/// A [ByteConnection] over a TCP socket.
class SocketConnection implements ByteConnection {
  SocketConnection(this._socket) {
    _socket.setOption(SocketOption.tcpNoDelay, true);
  }

  static Future<SocketConnection> connect(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    return SocketConnection(socket);
  }

  final Socket _socket;

  @override
  Stream<Uint8List> get input => _socket;

  @override
  void add(List<int> bytes) => _socket.add(bytes);

  @override
  Future<void> flush() => _socket.flush();

  @override
  Future<void> close() async {
    try {
      await _socket.close().timeout(const Duration(seconds: 2));
    } on Object {
      _socket.destroy();
    }
  }

  @override
  String get remoteAddress {
    try {
      return '${_socket.remoteAddress.address}:${_socket.remotePort}';
    } on SocketException {
      return 'closed';
    }
  }

  /// The remote host only, without the port.
  String get remoteHost {
    try {
      return _socket.remoteAddress.address;
    } on SocketException {
      return '';
    }
  }
}
