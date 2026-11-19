import 'package:ferret_wake/packet/wake_packet.dart';

/// Puts magic packets on the network.
abstract interface class WakeSender {
  /// Sends [packets] and returns the ones that went out. A system that
  /// refuses broadcasts (iOS without the multicast entitlement) still sends
  /// the direct ones.
  Future<List<WakePacket>> send(List<WakePacket> packets);
}
