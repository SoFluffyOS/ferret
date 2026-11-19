import 'package:ferret_wake/cards/ipv4_broadcast.dart';
import 'package:ferret_wake/cards/network_card.dart';
import 'package:ferret_wake/packet/packet.dart';
import 'package:protocol/protocol.dart';

/// Reads a Mac's network cards from `ifconfig`,
/// `networksetup -listallhardwareports` and `pmset -g`.
abstract final class MacosCards {
  static final _blockStart = RegExp(r'^([a-zA-Z0-9]+): flags=');
  static final _ether = RegExp(r'^\s+ether\s+(\S+)');
  static final _inet = RegExp(
    r'^\s+inet\s+(\d+\.\d+\.\d+\.\d+)\s+netmask\s+(0x[0-9a-fA-F]+)'
    r'(?:\s+broadcast\s+(\d+\.\d+\.\d+\.\d+))?',
  );
  static final _port = RegExp(r'^Hardware Port:\s*(.+)$');
  static final _device = RegExp(r'^Device:\s*(\S+)');
  static final _womp = RegExp(r'^\s*womp\s+(\d)', multiLine: true);

  /// The cards that are real hardware ports with an IPv4 address. Wi-Fi is
  /// the port named "Wi-Fi" (older macOS: "AirPort"); every other port is
  /// wired. "Wake for network access" (`womp`) applies to all of them.
  static List<NetworkCard> parse({
    required String ifconfig,
    required String hardwarePorts,
    required String pmset,
  }) {
    final ports = _ports(hardwarePorts);
    final setting = switch (_womp.firstMatch(pmset)?.group(1)) {
      '1' => WakeSetting.WAKE_SETTING_ON,
      '0' => WakeSetting.WAKE_SETTING_OFF,
      _ => WakeSetting.WAKE_SETTING_UNSPECIFIED,
    };

    final cards = <NetworkCard>[];
    for (final block in _blocks(ifconfig)) {
      final port = ports[block.name];
      if (port == null || block.name.startsWith('bridge')) {
        continue;
      }

      final mac = MacAddress.parse(block.ether ?? '');
      final address = block.address;
      if (mac == null || address == null) {
        continue;
      }

      final broadcast =
          block.broadcast ?? Ipv4Broadcast.of(address, block.prefix ?? 24);
      if (broadcast == null) {
        continue;
      }

      cards.add(
        NetworkCard(
          name: block.name,
          mac: mac,
          address: address,
          broadcast: broadcast,
          link: switch (port) {
            'Wi-Fi' || 'AirPort' => .WAKE_LINK_WIFI,
            _ => .WAKE_LINK_WIRED,
          },
          setting: setting,
        ),
      );
    }

    return cards;
  }

  /// Device name to hardware port name, such as `en0` to `Wi-Fi`.
  static Map<String, String> _ports(String hardwarePorts) {
    final ports = <String, String>{};
    String? port;
    for (final line in hardwarePorts.split('\n')) {
      if (_port.firstMatch(line) case final match?) {
        port = match.group(1)?.trim();
        continue;
      }

      if ((_device.firstMatch(line), port) case (
        final match?,
        final name?,
      )) {
        ports[match.group(1) ?? ''] = name;
      }
    }

    return ports;
  }

  static List<_Block> _blocks(String ifconfig) {
    final blocks = <_Block>[];
    for (final line in ifconfig.split('\n')) {
      if (_blockStart.firstMatch(line) case final match?) {
        blocks.add(_Block(match.group(1) ?? ''));
        continue;
      }

      final block = blocks.lastOrNull;
      if (block == null) {
        continue;
      }

      if (_ether.firstMatch(line) case final match?) {
        block.ether = match.group(1);
        continue;
      }

      if (_inet.firstMatch(line) case final match? when block.address == null) {
        block
          ..address = match.group(1)
          ..prefix = Ipv4Broadcast.prefixOfHexMask(match.group(2) ?? '')
          ..broadcast = match.group(3);
      }
    }

    return blocks;
  }
}

class _Block {
  _Block(this.name);

  final String name;
  String? ether;
  String? address;
  int? prefix;
  String? broadcast;
}
