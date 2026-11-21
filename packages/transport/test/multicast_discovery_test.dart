import 'dart:io';

import 'package:test/test.dart';
import 'package:transport/transport.dart';

void main() {
  test('broadcasts to each network once, not to everyone', () {
    final targets = MulticastDiscovery.broadcastTargets([
      InternetAddress('192.168.1.83'),
      InternetAddress('192.168.1.84'),
      InternetAddress('10.0.7.2'),
    ]);

    expect(targets.map((target) => target.address), [
      '192.168.1.255',
      '10.0.7.255',
    ]);
  });

  test('broadcasts to everyone when no network is known', () {
    final targets = MulticastDiscovery.broadcastTargets(const []);

    expect(targets.single.address, '255.255.255.255');
  });
}
