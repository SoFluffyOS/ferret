import 'dart:io';

/// Tells local network addresses from the rest of the internet.
abstract final class LocalNetworks {
  /// Whether [address] is on this machine or a private network: loopback,
  /// link-local, or the private IPv4 and IPv6 ranges.
  static bool contains(InternetAddress address) {
    if (address.isLoopback || address.isLinkLocal) {
      return true;
    }

    final bytes = address.rawAddress;
    if (address.type == InternetAddressType.IPv6) {
      return bytes[0] & 0xfe == 0xfc;
    }

    if (address.type != InternetAddressType.IPv4) {
      return false;
    }

    return switch ((bytes[0], bytes[1])) {
      (10, _) => true,
      (172, final second) => second >= 16 && second <= 31,
      (192, 168) => true,
      _ => false,
    };
  }
}
