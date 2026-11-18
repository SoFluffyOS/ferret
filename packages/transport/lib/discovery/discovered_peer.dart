import 'package:protocol/protocol.dart';

/// A device seen on the network, not yet connected or trusted.
class DiscoveredPeer {
  const DiscoveredPeer({required this.announce, required this.host});

  final Announce announce;

  /// The address the announce came from.
  final String host;

  String get deviceId => announce.deviceId;

  int get port => announce.port;
}

/// Finds Ferret devices nearby. Multicast is the default; Bluetooth or mDNS
/// can implement it too.
abstract interface class Discovery {
  Stream<DiscoveredPeer> get peers;

  Future<void> start(Announce self);

  /// Announces right away, such as when the network changed.
  Future<void> announceNow();

  Future<void> stop();
}

/// A [Discovery] that can also look on demand, says when a device left, and
/// knows when the system keeps it from looking at all.
abstract interface class ActiveDiscovery implements Discovery {
  /// Asks the network who is there and waits a moment for the answers.
  Future<void> scan();

  /// The ids of devices that said goodbye or stopped answering.
  Stream<String> get departures;

  /// Whether the system refused everything sent last time, which is what a
  /// missing local network permission looks like.
  bool get isBlocked;
}
