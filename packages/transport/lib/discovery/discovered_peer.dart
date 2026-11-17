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
