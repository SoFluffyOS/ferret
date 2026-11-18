import 'dart:io';
import 'dart:typed_data';

/// A two-way stream of bytes to something on a device, such as a socket a
/// program listens on there.
abstract interface class AdbConnection {
  /// What the device sends. Listened to once.
  Stream<Uint8List> get input;

  void add(List<int> bytes);

  void close();
}

/// A connection that is a plain socket on this computer, such as a port
/// adb forwards to the device.
class SocketAdbConnection implements AdbConnection {
  SocketAdbConnection(this._socket) {
    _socket.setOption(.tcpNoDelay, true);
    _socket.done.ignore();
  }

  final Socket _socket;

  @override
  Stream<Uint8List> get input => _socket;

  @override
  void add(List<int> bytes) {
    try {
      _socket.add(bytes);
    } on StateError {
      // Closing: whoever reads [input] sees the end.
    }
  }

  @override
  void close() => _socket.destroy();
}
