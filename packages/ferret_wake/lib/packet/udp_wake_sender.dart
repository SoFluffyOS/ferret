import 'dart:io';

import 'package:core/core.dart';
import 'package:ferret_wake/packet/wake_packet.dart';
import 'package:ferret_wake/packet/wake_sender.dart';

/// Sends magic packets as UDP datagrams from one socket.
class UdpWakeSender implements WakeSender {
  const UdpWakeSender();

  @override
  Future<List<WakePacket>> send(List<WakePacket> packets) async {
    if (packets.isEmpty) {
      return const [];
    }

    final RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } on SocketException catch (error) {
      printWarning('Wake-on-LAN socket refused', error);
      return const [];
    }

    final sent = <WakePacket>[];
    try {
      socket.broadcastEnabled = true;
      for (final packet in packets) {
        if (_sendOne(socket, packet)) {
          sent.add(packet);
        }
      }
    } on Object catch (error) {
      printWarning('Wake-on-LAN socket failed', error);
    } finally {
      socket.close();
    }

    return sent;
  }

  bool _sendOne(RawDatagramSocket socket, WakePacket packet) {
    try {
      final written = socket.send(
        packet.bytes,
        InternetAddress(packet.address),
        packet.port,
      );
      return written == packet.bytes.length;
    } on Object {
      return false;
    }
  }
}
