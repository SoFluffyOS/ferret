import 'dart:convert';

import 'package:ferret_wake/cards/ipv4_broadcast.dart';
import 'package:ferret_wake/cards/network_card.dart';
import 'package:ferret_wake/packet/packet.dart';

/// Reads a Windows computer's network cards from [script]'s JSON.
abstract final class WindowsCards {
  /// PowerShell that lists the physical cards that are up, with their
  /// IPv4 address and whether "Wake on Magic Packet" is on. Plain property
  /// names, so the output reads the same in every Windows language.
  static const script = r'''
$ErrorActionPreference = 'SilentlyContinue'
@(Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | ForEach-Object {
  $ip = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1
  $power = Get-NetAdapterPowerManagement -Name $_.Name
  [pscustomobject]@{
    Name = $_.Name
    Mac = $_.MacAddress
    Media = $_.PhysicalMediaType
    Address = $ip.IPAddress
    Prefix = $ip.PrefixLength
    Magic = "$($power.WakeOnMagicPacket)"
  }
}) | ConvertTo-Json -Compress
''';

  /// The cards in [json]: one object or a list of them. Wi-Fi is media
  /// "Native 802.11" or "Wireless LAN"; everything else is wired.
  static List<NetworkCard> parse(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json.trim());
    } on FormatException {
      return const [];
    }

    final entries = switch (decoded) {
      final List<Object?> list => list,
      final Map<String, Object?> one => [one],
      _ => const <Object?>[],
    };

    return [
      for (final entry in entries)
        if (entry case final Map<String, Object?> card) ?_card(card),
    ];
  }

  static NetworkCard? _card(Map<String, Object?> card) {
    final mac = MacAddress.parse('${card['Mac'] ?? ''}');
    final address = '${card['Address'] ?? ''}';
    final prefix = switch (card['Prefix']) {
      final num value => value.toInt(),
      _ => 24,
    };
    final broadcast = Ipv4Broadcast.of(address, prefix);
    if (mac == null || broadcast == null) {
      return null;
    }

    final media = '${card['Media'] ?? ''}'.toLowerCase();
    return NetworkCard(
      name: '${card['Name'] ?? ''}',
      mac: mac,
      address: address,
      broadcast: broadcast,
      link: switch (media.contains('802.11') || media.contains('wireless')) {
        true => .WAKE_LINK_WIFI,
        false => .WAKE_LINK_WIRED,
      },
      setting: switch ('${card['Magic'] ?? ''}'.toLowerCase()) {
        'enabled' => .WAKE_SETTING_ON,
        'disabled' || 'unsupported' => .WAKE_SETTING_OFF,
        _ => .WAKE_SETTING_UNSPECIFIED,
      },
    );
  }
}
