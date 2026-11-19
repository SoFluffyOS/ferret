import 'dart:io';

/// Works out a network's broadcast address from an address and its mask.
abstract final class Ipv4Broadcast {
  /// The broadcast address of [address]'s network with a [prefixLength]
  /// bit mask, such as `192.168.1.255` for `192.168.1.20/24`. Null when
  /// [address] isn't IPv4 or the prefix is out of range.
  static String? of(String address, int prefixLength) {
    final parsed = InternetAddress.tryParse(address);
    if (parsed == null || parsed.type != InternetAddressType.IPv4) {
      return null;
    }

    if (prefixLength < 0 || prefixLength > 32) {
      return null;
    }

    final value = parsed.rawAddress.fold(0, (sum, byte) => sum << 8 | byte);
    final hostBits = (1 << (32 - prefixLength)) - 1;
    final broadcast = value | hostBits;
    return [
      for (final shift in const [24, 16, 8, 0]) (broadcast >> shift) & 0xff,
    ].join('.');
  }

  /// The prefix length of a hex mask such as `0xffffff00` (24), as macOS's
  /// ifconfig prints it. Null when it isn't one.
  static int? prefixOfHexMask(String mask) {
    final digits = mask.toLowerCase().replaceFirst('0x', '');
    final value = int.tryParse(digits, radix: 16);
    if (value == null) {
      return null;
    }

    final bits = value.toRadixString(2).padLeft(32, '0');
    if (bits.length != 32 || bits.contains('01')) {
      return null;
    }

    return '1'.allMatches(bits).length;
  }
}
