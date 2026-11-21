import 'dart:io';

import 'package:protocol/protocol.dart';
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

  test('a question names nobody, and older versions ignore it', () {
    expect(MulticastDiscovery.question, [0x46, 0x52, 0x54, 0x02]);
    expect(isQuestion(MulticastDiscovery.question), isTrue);
    expect(decodeAnnounce(MulticastDiscovery.question), isNull);
    expect(
      isQuestion(encodeAnnounce(Announce(deviceId: 'abcdabcdabcdabcd'))),
      isFalse,
    );
  });

  test('announcing can be turned off before it starts', () async {
    final discovery = MulticastDiscovery();

    await discovery.setAnnouncing(false);

    expect(discovery.isAnnouncing, isFalse);
  });
}
