/// What Linux's `/sys/class/net/<card>` and `ethtool <card>` say about one
/// card.
class LinuxCardFacts {
  const LinuxCardFacts({
    required this.mac,
    required this.isWireless,
    required this.isHardware,
    this.ethtool,
  });

  /// The contents of `address`.
  final String mac;

  /// Whether it has a `wireless` or `phy80211` entry.
  final bool isWireless;

  /// Whether it has a `device` entry: a real card, not a bridge, VPN or
  /// container interface.
  final bool isHardware;

  /// What `ethtool <card>` printed, or null when it isn't installed.
  final String? ethtool;
}
