import 'package:ferret_wake/cards/ipv4_broadcast.dart';
import 'package:ferret_wake/cards/linux_card_facts.dart';
import 'package:ferret_wake/cards/network_card.dart';
import 'package:ferret_wake/packet/packet.dart';
import 'package:protocol/protocol.dart';

/// Reads a Linux computer's network cards from `ip -o -4 addr show` and
/// what [LinuxCardFacts] gathered for each.
abstract final class LinuxCards {
  static final _line = RegExp(
    r'^\d+:\s+(\S+)\s+inet\s+(\d+\.\d+\.\d+\.\d+)/(\d+)'
    r'(?:\s+brd\s+(\d+\.\d+\.\d+\.\d+))?',
  );
  static final _wakeOn = RegExp(r'^\s*Wake-on:\s*(\S+)', multiLine: true);

  /// The card names in [ipAddr], so the facts can be gathered for them.
  static List<String> names(String ipAddr) => [
    for (final line in ipAddr.split('\n')) ?_line.firstMatch(line)?.group(1),
  ];

  /// The hardware cards with an IPv4 address. Wake-on-LAN is on when
  /// ethtool's `Wake-on` holds `g` (magic packet), off when it doesn't.
  static List<NetworkCard> parse(
    String ipAddr,
    Map<String, LinuxCardFacts> facts,
  ) {
    final cards = <NetworkCard>[];
    final seen = <String>{};
    for (final line in ipAddr.split('\n')) {
      final match = _line.firstMatch(line);
      if (match == null) {
        continue;
      }

      final name = match.group(1) ?? '';
      final address = match.group(2) ?? '';
      final fact = facts[name];
      if (fact == null || !fact.isHardware || !seen.add(name)) {
        continue;
      }

      final mac = MacAddress.parse(fact.mac);
      final broadcast =
          match.group(4) ??
          Ipv4Broadcast.of(address, int.tryParse(match.group(3) ?? '') ?? 24);
      if (mac == null || broadcast == null) {
        continue;
      }

      cards.add(
        NetworkCard(
          name: name,
          mac: mac,
          address: address,
          broadcast: broadcast,
          link: switch (fact.isWireless) {
            true => .WAKE_LINK_WIFI,
            false => .WAKE_LINK_WIRED,
          },
          setting: _setting(fact.ethtool),
        ),
      );
    }

    return cards;
  }

  static WakeSetting _setting(String? ethtool) {
    final modes = _wakeOn.allMatches(ethtool ?? '').lastOrNull?.group(1);
    if (modes == null) {
      return .WAKE_SETTING_UNSPECIFIED;
    }

    if (modes.contains('g')) {
      return .WAKE_SETTING_ON;
    }

    return .WAKE_SETTING_OFF;
  }
}
