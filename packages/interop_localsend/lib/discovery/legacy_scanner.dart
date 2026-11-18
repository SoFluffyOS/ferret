import 'dart:async';
import 'dart:io';

import 'package:interop_localsend/client/client.dart';
import 'package:interop_localsend/models/models.dart';
import 'package:interop_localsend/server/local_networks.dart';

/// Finds LocalSend members by asking every address on the local network
/// (protocol section 3.2), for networks where multicast doesn't get
/// through.
class LegacyScanner {
  LegacyScanner({
    required this.client,
    this.port = LocalSendDefaults.port,
    this.parallel = 48,
    this.timeout = const Duration(milliseconds: 1500),
  });

  final LocalSendClient client;
  final int port;

  /// How many addresses are asked at the same time.
  final int parallel;
  final Duration timeout;

  /// The other 253 addresses of [own]'s /24 network, or none when [own]
  /// isn't a private IPv4 address. Larger networks aren't swept.
  static List<InternetAddress> neighbours(InternetAddress own) {
    if (own.type != InternetAddressType.IPv4 ||
        own.isLoopback ||
        !LocalNetworks.contains(own)) {
      return const [];
    }

    final bytes = own.rawAddress;
    return [
      for (var host = 1; host < 255; host++)
        if (host != bytes[3])
          InternetAddress('${bytes[0]}.${bytes[1]}.${bytes[2]}.$host'),
    ];
  }

  /// The addresses to ask from this machine's network interfaces.
  static Future<List<InternetAddress>> localNeighbours() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      return [
        for (final interface in interfaces)
          for (final address in interface.addresses) ...neighbours(address),
      ];
    } on Object {
      return const [];
    }
  }

  /// Asks each of [addresses] and reports the members that answer through
  /// [onFound]. Completes when every address answered or timed out.
  Future<void> scan(
    LocalSendInfo self,
    List<InternetAddress> addresses, {
    required void Function(LocalSendPeer peer) onFound,
  }) async {
    var next = 0;
    Future<void> worker() async {
      while (next < addresses.length) {
        final address = addresses[next++];
        final peer = await client.probe(
          address,
          self,
          port: port,
          timeout: timeout,
        );
        if (peer != null) {
          onFound(peer);
        }
      }
    }

    await Future.wait([
      for (var index = 0; index < parallel; index++) worker(),
    ]);
  }
}
