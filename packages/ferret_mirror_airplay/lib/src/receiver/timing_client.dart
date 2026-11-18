import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Asks the phone for its clock every few seconds over UDP, as an AirPlay
/// receiver is expected to. Ferret shows pictures as they arrive, so the
/// answers aren't used; the questions keep the phone's session healthy.
class TimingClient {
  static const _every = Duration(seconds: 3);

  /// Seconds between 1900, where NTP time starts, and the Unix epoch.
  static const _ntpEpochOffset = 2208988800;

  RawDatagramSocket? _socket;
  Timer? _timer;

  /// Starts asking [remote] on [remotePort], and returns the local port
  /// the phone is told about. A [remotePort] of 0 only opens the port.
  Future<int> start(InternetAddress remote, int remotePort) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        socket.receive();
      }
    }, onError: (Object _) {});
    _socket = socket;
    if (remotePort > 0) {
      _send(remote, remotePort);
      _timer = .periodic(_every, (_) => _send(remote, remotePort));
    }

    return socket.port;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
  }

  /// A 32-byte timing request, with the time it is sent at in its last
  /// 8 bytes as NTP seconds and fraction.
  static Uint8List request(DateTime now) {
    final packet = Uint8List(32);
    final micros = now.microsecondsSinceEpoch;
    final seconds = micros ~/ 1000000 + _ntpEpochOffset;
    final fraction = ((micros % 1000000) << 32) ~/ 1000000;
    packet
      ..[0] = 0x80
      ..[1] = 0xd2
      ..[3] = 0x07;
    ByteData.sublistView(packet)
      ..setUint32(24, seconds & 0xffffffff)
      ..setUint32(28, fraction & 0xffffffff);
    return packet;
  }

  void _send(InternetAddress remote, int remotePort) {
    try {
      _socket?.send(request(DateTime.now()), remote, remotePort);
    } on SocketException {
      return;
    }
  }
}
