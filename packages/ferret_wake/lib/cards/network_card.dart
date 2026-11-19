import 'dart:typed_data';

import 'package:protocol/protocol.dart';

/// One of this computer's wired or Wi-Fi network cards, as far as waking it
/// goes.
class NetworkCard {
  const NetworkCard({
    required this.name,
    required this.mac,
    required this.address,
    required this.broadcast,
    required this.link,
    this.setting = .WAKE_SETTING_UNSPECIFIED,
  });

  /// The system's name for it, such as `en0`, `enp3s0` or `Ethernet`.
  /// Stays on this computer.
  final String name;
  final Uint8List mac;
  final String address;
  final String broadcast;
  final WakeLink link;
  final WakeSetting setting;

  NetworkCard withSetting(WakeSetting setting) => NetworkCard(
    name: name,
    mac: mac,
    address: address,
    broadcast: broadcast,
    link: link,
    setting: setting,
  );

  WakeInterface toInterface() => WakeInterface(
    mac: mac,
    address: address,
    broadcast: broadcast,
    link: link,
    setting: setting,
  );

  /// What this computer tells its paired devices: [cards], wired first.
  static WakeInfo shareable(List<NetworkCard> cards) {
    final ordered = [...cards]
      ..sort((first, second) => _rank(first).compareTo(_rank(second)));

    return WakeInfo(
      interfaces: [for (final card in ordered) card.toInterface()],
    );
  }

  static int _rank(NetworkCard card) => switch (card.link) {
    .WAKE_LINK_WIRED => 0,
    .WAKE_LINK_WIFI => 1,
    _ => 2,
  };
}
