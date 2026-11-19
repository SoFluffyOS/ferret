import 'dart:typed_data';

/// One magic packet and where it goes.
class WakePacket {
  const WakePacket({
    required this.bytes,
    required this.address,
    required this.port,
    required this.isBroadcast,
  });

  final Uint8List bytes;

  /// An IPv4 address, such as `192.168.1.255`.
  final String address;
  final int port;

  /// Sent to a whole network rather than to the computer's last address.
  /// Only a broadcast reaches a computer that is fully asleep: its old
  /// address no longer answers on the network.
  final bool isBroadcast;
}
