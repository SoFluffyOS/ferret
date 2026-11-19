import 'dart:typed_data';

import 'package:ferret_wake/packet/mac_address.dart';

/// The Wake-on-LAN "magic packet": six 0xFF bytes, then the card's MAC
/// address sixteen times. A sleeping card that has Wake-on-LAN on powers
/// the computer up when it sees its own address repeated like this.
abstract final class MagicPacket {
  static const length = 6 + 16 * MacAddress.length;

  /// The packet that wakes the card with [mac]. Throws an [ArgumentError]
  /// when [mac] isn't six bytes.
  static Uint8List of(List<int> mac) {
    if (mac.length != MacAddress.length) {
      throw ArgumentError.value(mac, 'mac', 'must be 6 bytes');
    }

    final packet = Uint8List(length)..fillRange(0, 6, 0xff);
    for (var copy = 0; copy < 16; copy++) {
      packet.setRange(
        6 + copy * MacAddress.length,
        6 + (copy + 1) * MacAddress.length,
        mac,
      );
    }

    return packet;
  }
}
