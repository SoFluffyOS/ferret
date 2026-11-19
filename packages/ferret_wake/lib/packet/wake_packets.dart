import 'dart:io';

import 'package:ferret_wake/packet/mac_address.dart';
import 'package:ferret_wake/packet/magic_packet.dart';
import 'package:ferret_wake/packet/wake_packet.dart';
import 'package:protocol/protocol.dart';

/// Every magic packet that may wake a computer.
abstract final class WakePackets {
  /// The usual Wake-on-LAN ports: 9 (discard) and 7 (echo).
  static const ports = [9, 7];

  /// Broadcast to the network the sender is on, whatever it is.
  static const everywhere = '255.255.255.255';

  /// For each network card in [info]: to that card's network broadcast, to
  /// [everywhere], and to [lastAddress] (where the computer was last
  /// reached), on each of [ports]. Empty when [info] has no usable card.
  static List<WakePacket> of(WakeInfo info, {String? lastAddress}) {
    final direct = switch (lastAddress) {
      final address? when _isIpv4(address) => address,
      _ => null,
    };

    return [
      for (final card in info.interfaces)
        if (MacAddress.isUsable(card.mac))
          for (final (address, isBroadcast) in {
            if (_isIpv4(card.broadcast)) (card.broadcast, true),
            (everywhere, true),
            if (direct != null) (direct, false),
          })
            for (final port in ports)
              WakePacket(
                bytes: MagicPacket.of(card.mac),
                address: address,
                port: port,
                isBroadcast: isBroadcast,
              ),
    ];
  }

  static bool _isIpv4(String address) =>
      InternetAddress.tryParse(address)?.type == InternetAddressType.IPv4;
}
