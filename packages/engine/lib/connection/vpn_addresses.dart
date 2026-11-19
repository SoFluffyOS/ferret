import 'dart:io';

/// Finds this device's addresses on the user's own VPN (Tailscale,
/// ZeroTier, WireGuard), and checks the ones another device reports.
class VpnAddresses {
  const VpnAddresses({this.allowLoopback = false});

  /// Lets loopback addresses through [accept], for tests that stand a
  /// second loopback address in for a VPN.
  final bool allowLoopback;

  /// The most addresses kept per device, so a device can't hand over a
  /// long list to dial.
  static const maxAddresses = 8;

  static const _vpnInterfacePrefixes = [
    'tailscale',
    'utun',
    'tun',
    'wg',
    'zt',
    'feth',
  ];

  /// Mobile data interfaces. Carriers hand out addresses from the same
  /// 100.64.0.0/10 range Tailscale uses, and those must never be shared.
  static const _cellularPrefixes = ['rmnet', 'ccmni', 'pdp_ip', 'wwan', 'v4-'];

  /// Whether [name] is a VPN interface, such as `tailscale0`, `utun4`,
  /// `wg0` or `ztabcdef12`.
  static bool isVpnInterface(String name) {
    final lower = name.toLowerCase();
    return _vpnInterfacePrefixes.any(lower.startsWith);
  }

  static bool _isCellularInterface(String name) {
    final lower = name.toLowerCase();
    return _cellularPrefixes.any(lower.startsWith);
  }

  /// Whether [address] is in a range Tailscale hands out: 100.64.0.0/10 or
  /// fd7a:115c:a1e0::/48.
  static bool isTailscaleRange(InternetAddress address) {
    final bytes = address.rawAddress;
    return switch (address.type) {
      InternetAddressType.IPv4 => bytes[0] == 100 && (bytes[1] & 0xC0) == 64,
      InternetAddressType.IPv6 =>
        bytes[0] == 0xfd &&
            bytes[1] == 0x7a &&
            bytes[2] == 0x11 &&
            bytes[3] == 0x5c &&
            bytes[4] == 0xa1 &&
            bytes[5] == 0xe0,
      _ => false,
    };
  }

  /// The addresses of [interfaces] worth sharing: those on a VPN
  /// interface, and those in Tailscale's ranges on any interface but
  /// mobile data. Loopback and link-local ones never are.
  static List<String> select(
    Iterable<({String name, List<InternetAddress> addresses})> interfaces,
  ) {
    final found = <String>[];
    for (final interface in interfaces) {
      if (_isCellularInterface(interface.name)) {
        continue;
      }

      final onVpn = isVpnInterface(interface.name);
      for (final address in interface.addresses) {
        if (address.isLoopback || address.isLinkLocal) {
          continue;
        }

        if (onVpn || isTailscaleRange(address)) {
          found.add(address.address);
        }
      }
    }

    return found.take(maxAddresses).toList();
  }

  /// This device's VPN addresses right now.
  static Future<List<String>> ofThisDevice() async {
    try {
      final interfaces = await NetworkInterface.list();
      return select([
        for (final interface in interfaces)
          (name: interface.name, addresses: [...interface.addresses]),
      ]);
    } on Object {
      return const [];
    }
  }

  /// The addresses from another device worth remembering: IP addresses
  /// only, no names, never loopback, link-local, multicast or "any", no
  /// repeats, at most [maxAddresses].
  List<String> accept(Iterable<String> reported) {
    final accepted = <String>[];
    for (final text in reported) {
      final address = InternetAddress.tryParse(text.trim());
      if (address == null || !_isDialable(address)) {
        continue;
      }

      if (accepted.contains(address.address)) {
        continue;
      }

      accepted.add(address.address);
      if (accepted.length == maxAddresses) {
        break;
      }
    }

    return accepted;
  }

  bool _isDialable(InternetAddress address) {
    if (address.isLinkLocal || address.isMulticast) {
      return false;
    }

    if (address.isLoopback) {
      return allowLoopback;
    }

    return address.rawAddress.any((byte) => byte != 0);
  }

  /// Whether a session with [host] runs over the VPN: [host] is one of
  /// [known] (the device's reported VPN addresses and the address typed
  /// for it), or a Tailscale address.
  static bool isVpnHost(String host, Iterable<String> known) {
    if (known.contains(host)) {
      return true;
    }

    return switch (InternetAddress.tryParse(host)) {
      final address? => isTailscaleRange(address),
      null => false,
    };
  }

  /// Splits an address the user typed, such as "100.64.1.2",
  /// "pixel.tail1234.ts.net:47640" or "[fd7a::1]:47640", into host and
  /// port, with [defaultPort] when it names none.
  static (String host, int port) parseTyped(String typed, int defaultPort) {
    final text = typed.trim();
    if (text.startsWith('[')) {
      final close = text.indexOf(']');
      if (close > 0) {
        final host = text.substring(1, close);
        final port = switch (text.substring(close + 1)) {
          final rest when rest.startsWith(':') => int.tryParse(
            rest.substring(1),
          ),
          _ => null,
        };
        return (host, port ?? defaultPort);
      }
    }

    final colon = text.lastIndexOf(':');
    final isHostWithPort = colon > 0 && text.indexOf(':') == colon;
    if (!isHostWithPort) {
      return (text, defaultPort);
    }

    final port = int.tryParse(text.substring(colon + 1));
    if (port == null || port <= 0 || port > 65535) {
      return (text, defaultPort);
    }

    return (text.substring(0, colon), port);
  }
}
