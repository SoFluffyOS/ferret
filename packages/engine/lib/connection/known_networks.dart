import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/connection/vpn_addresses.dart';
import 'package:transport/transport.dart';

/// One local network this device has an address on.
class LocalNetwork {
  const LocalNetwork({required this.subnet, this.gatewayMac});

  /// The first three parts of this device's address, the /24 Ferret takes
  /// every home network to be, such as `192.168.1`.
  final String subnet;

  /// The router's hardware address, where the system shows it without a
  /// permission: on a Mac and Linux. It tells apart two networks that hand
  /// out the same addresses, like home and a café on the same router brand.
  final String? gatewayMac;

  /// Whether [host] is on this network.
  bool contains(String host) => subnetOf(host) == subnet;

  /// The /24 of an IPv4 [host], or null for anything else.
  static String? subnetOf(String host) {
    final address = InternetAddress.tryParse(host);
    if (address == null || address.type != InternetAddressType.IPv4) {
      return null;
    }

    final bytes = address.rawAddress;
    return '${bytes[0]}.${bytes[1]}.${bytes[2]}';
  }

  @override
  String toString() => 'LocalNetwork($subnet, ${gatewayMac ?? 'no router'})';
}

/// Lists the local networks this device is on right now.
typedef LocalNetworkSource = Future<List<LocalNetwork>> Function();

/// The networks where this device met one of its paired devices, so it
/// announces itself there and stays quiet everywhere else.
///
/// Each one is kept as a hash of its /24 and, where the system shows it,
/// its router's hardware address, salted with this device's id: the
/// settings file doesn't say where you've been. No Wi-Fi name, which needs
/// the location permission on every system.
class KnownNetworks {
  KnownNetworks(
    this._settings, {
    required String salt,
    LocalNetworkSource? source,
  }) : _salt = salt,
       _source = source ?? LocalNetworks.ofThisDevice;

  static const settingsKey = 'discovery.known_networks';

  /// The most networks kept; the one met longest ago goes first.
  static const maxKept = 32;

  final SettingsStore _settings;
  final String _salt;
  final LocalNetworkSource _source;
  List<LocalNetwork> _current = const [];

  /// The networks found at the last [refresh].
  List<LocalNetwork> get current => _current;

  /// Whether no network was ever remembered, such as right after updating
  /// from a Ferret that announced everywhere: then it keeps announcing until
  /// it meets a paired device, so the two find each other once.
  bool get isLearning => _settings.get<List<Object?>>(settingsKey) == null;

  List<String> get _records => [
    for (final record in _settings.get<List<Object?>>(settingsKey) ?? const [])
      if (record is String) record,
  ];

  /// Looks at the networks again, such as after the network changed.
  Future<List<LocalNetwork>> refresh() async {
    try {
      _current = await _source();
    } on Object catch (error) {
      printDebug('Could not list the local networks: $error');
      _current = const [];
    }

    return _current;
  }

  /// Whether this device is on a network where it met a paired device.
  Future<bool> isOnKnown() async {
    final records = _records;
    for (final network in _current) {
      if (await _matches(network, records)) {
        return true;
      }
    }

    return false;
  }

  /// Remembers the network that holds [host], where a paired device was
  /// just reached. Returns whether it is new. A host on none of this
  /// device's networks, such as one reached through a router, isn't kept.
  Future<bool> rememberHost(String host) async {
    var network = _find(host);
    if (network == null) {
      await refresh();
      network = _find(host);
    }

    if (network == null) {
      return false;
    }

    final subnet = await _hash(network.subnet);
    final mac = switch (network.gatewayMac) {
      final mac? => await _hash(mac),
      null => '',
    };
    final record = '$subnet:$mac';
    final records = _records;
    final wasKnown = await _matches(network, records);
    final kept = [
      record,
      for (final old in records)
        if (old != record && !(mac.isNotEmpty && old == '$subnet:')) old,
    ];
    await _settings.set(settingsKey, kept.take(maxKept).toList());
    return !wasKnown;
  }

  /// Forgets every network, such as when the last paired device is gone.
  Future<void> forget() => _settings.set(settingsKey, const <String>[]);

  LocalNetwork? _find(String host) {
    for (final network in _current) {
      if (network.contains(host)) {
        return network;
      }
    }

    return null;
  }

  /// A record matches on its /24; when both it and [network] know their
  /// router, the router has to match too.
  Future<bool> _matches(LocalNetwork network, List<String> records) async {
    final subnet = await _hash(network.subnet);
    final mac = switch (network.gatewayMac) {
      final mac? => await _hash(mac),
      null => null,
    };
    for (final record in records) {
      final parts = record.split(':');
      if (parts.length != 2 || parts[0] != subnet) {
        continue;
      }

      if (parts[1].isEmpty || mac == null || parts[1] == mac) {
        return true;
      }
    }

    return false;
  }

  Future<String> _hash(String value) async {
    final digest = await NoiseCrypto.hash(utf8.encode('$_salt|$value'));
    return base64Url.encode(digest.sublist(0, 12));
  }
}

/// Reads this device's local networks from the system.
abstract final class LocalNetworks {
  /// Every IPv4 network this device is on, apart from loopback, link-local,
  /// VPN and mobile data ones, with the router's hardware address where the
  /// system shows it without asking.
  static Future<List<LocalNetwork>> ofThisDevice() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    final subnets = <String>{};
    for (final interface in interfaces) {
      if (VpnAddresses.isVpnInterface(interface.name) ||
          VpnAddresses.isCellularInterface(interface.name)) {
        continue;
      }

      for (final address in interface.addresses) {
        if (address.isLoopback ||
            address.isLinkLocal ||
            VpnAddresses.isTailscaleRange(address)) {
          continue;
        }

        if (LocalNetwork.subnetOf(address.address) case final subnet?) {
          subnets.add(subnet);
        }
      }
    }

    final router = await _router();
    return [
      for (final subnet in subnets)
        LocalNetwork(
          subnet: subnet,
          gatewayMac: switch (router) {
            (:final host, :final mac)
                when LocalNetwork.subnetOf(host) == subnet =>
              mac,
            _ => null,
          },
        ),
    ];
  }

  /// The default router's address and hardware address, on a Mac and
  /// Linux. Phones don't show it to apps, and Windows isn't read yet.
  static Future<({String host, String mac})?> _router() async {
    try {
      if (Platform.isMacOS) {
        return await _routerOnMac();
      }

      if (Platform.isLinux) {
        return await _routerOnLinux();
      }
    } on Object catch (error) {
      printDebug('Could not read the router: $error');
    }

    return null;
  }

  static Future<({String host, String mac})?> _routerOnMac() async {
    final route = await Process.run('/sbin/route', ['-n', 'get', 'default']);
    final host = macGateway('${route.stdout}');
    if (host == null) {
      return null;
    }

    final arp = await Process.run('/usr/sbin/arp', ['-n', host]);
    final mac = arpMac('${arp.stdout}');
    return mac == null ? null : (host: host, mac: mac);
  }

  static Future<({String host, String mac})?> _routerOnLinux() async {
    final host = linuxGateway(await File('/proc/net/route').readAsString());
    if (host == null) {
      return null;
    }

    final mac = linuxArpMac(await File('/proc/net/arp').readAsString(), host);
    return mac == null ? null : (host: host, mac: mac);
  }

  /// The gateway in `route -n get default`'s output.
  static String? macGateway(String output) {
    final match = RegExp(
      r'^\s*gateway:\s*(\d+\.\d+\.\d+\.\d+)\s*$',
      multiLine: true,
    ).firstMatch(output);
    return match?.group(1);
  }

  /// The hardware address in `arp -n <host>`'s output, such as
  /// `? (192.168.1.1) at a4:2b:b0:1:2:3 on en0 ifscope [ethernet]`.
  static String? arpMac(String output) {
    final match = RegExp(
      r' at ([0-9a-fA-F]{1,2}(?::[0-9a-fA-F]{1,2}){5}) ',
    ).firstMatch(output);
    return match == null ? null : normalizeMac(match.group(1)!);
  }

  /// The default route's gateway in `/proc/net/route`, where addresses are
  /// little-endian hex.
  static String? linuxGateway(String table) {
    for (final line in table.split('\n').skip(1)) {
      final fields = line.trim().split(RegExp(r'\s+'));
      if (fields.length < 3 || fields[1] != '00000000') {
        continue;
      }

      final value = int.tryParse(fields[2], radix: 16);
      if (value == null || value == 0) {
        continue;
      }

      return [
        value & 0xff,
        (value >> 8) & 0xff,
        (value >> 16) & 0xff,
        (value >> 24) & 0xff,
      ].join('.');
    }

    return null;
  }

  /// [host]'s hardware address in `/proc/net/arp`.
  static String? linuxArpMac(String table, String host) {
    for (final line in table.split('\n').skip(1)) {
      final fields = line.trim().split(RegExp(r'\s+'));
      if (fields.length < 4 || fields[0] != host) {
        continue;
      }

      final mac = fields[3];
      if (mac == '00:00:00:00:00:00') {
        return null;
      }

      return normalizeMac(mac);
    }

    return null;
  }

  /// Lowercase with two digits per part, since macOS drops leading zeros.
  static String normalizeMac(String mac) => [
    for (final part in mac.toLowerCase().split(':')) part.padLeft(2, '0'),
  ].join(':');
}

/// Keeps this device announced until [release], from
/// `FerretEngine.stayVisible`.
class VisibleHold {
  VisibleHold(this._onRelease);

  final void Function() _onRelease;
  bool _released = false;

  /// Lets the device go quiet again where it would be. Only the first call
  /// counts.
  void release() {
    if (_released) {
      return;
    }

    _released = true;
    _onRelease();
  }
}
