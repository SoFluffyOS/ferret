// Announces a pretend device and prints every Ferret device found on the
// network, to try discovery against real devices:
//
//   dart run tool/discover.dart [seconds] [name]
//
// ignore_for_file: avoid_print
import 'dart:async';

import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

Future<void> main(List<String> arguments) async {
  final seconds = switch (arguments) {
    [final first, ...] => int.tryParse(first) ?? 20,
    _ => 20,
  };
  final name = switch (arguments) {
    [_, final second, ...] => second,
    _ => 'Discovery test',
  };
  final ways = <String, ActiveDiscovery>{
    'multicast': MulticastDiscovery(),
    'mdns': MdnsDiscovery(),
  };
  final self = Announce(
    protocolVersion: 1,
    deviceId: 'discoverytest${DateTime.now().millisecond % 900 + 100}',
    name: name,
    platform: .PLATFORM_CLI,
    formFactor: .FORM_FACTOR_DESKTOP,
    port: 9,
  );

  for (final MapEntry(key: way, value: discovery) in ways.entries) {
    final seen = <String>{};
    discovery.peers.listen((peer) {
      if (seen.add(peer.deviceId)) {
        print(
          '[$way] found ${peer.announce.name} (${peer.deviceId}) '
          'at ${peer.host}:${peer.port}',
        );
      }
    });
    discovery.departures.listen((deviceId) {
      seen.remove(deviceId);
      print('[$way] gone $deviceId');
    });
    try {
      await discovery.start(self);
    } on Object catch (error) {
      print('[$way] did not start: $error');
    }
  }

  print('Looking for $seconds s as "$name" (${self.deviceId})…');
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await Future.wait([for (final discovery in ways.values) discovery.scan()]);
    for (final MapEntry(key: way, value: discovery) in ways.entries) {
      if (discovery.isBlocked) {
        print('[$way] the system refused every packet');
      }
    }

    await Future<void>.delayed(const Duration(seconds: 3));
  }

  for (final discovery in ways.values) {
    await discovery.stop();
  }
}
