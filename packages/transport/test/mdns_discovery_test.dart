import 'dart:async';
import 'dart:io';

import 'package:lan_discovery/lan_discovery.dart';
import 'package:lan_discovery/testing/testing.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

Announce _announce(String id, String name, {int port = 47640}) => Announce(
  protocolVersion: 1,
  deviceId: id,
  name: name,
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  port: port,
);

void main() {
  late MemoryMdnsNetwork network;
  final running = <MdnsDiscovery>[];

  setUp(() => network = MemoryMdnsNetwork());

  tearDown(() async {
    for (final discovery in running) {
      await discovery.stop();
    }

    running.clear();
  });

  MdnsDiscovery join({bool sharesPort = true}) {
    final discovery = MdnsDiscovery(
      collectFor: const Duration(milliseconds: 1300),
      open: () async => network.join(sharesPort: sharesPort),
    );
    running.add(discovery);
    return discovery;
  }

  test('the TXT record round-trips what an announce says', () {
    final announce = _announce('abcdefgh234567ab', 'Pixel 7 ✨', port: 50123);
    final service = MdnsDiscovery.serviceFor(announce);

    final read = MdnsDiscovery.announceFrom(
      MdnsInstance(
        name: service.instance,
        address: InternetAddress('192.168.1.5'),
        port: service.port,
        txt: service.txt,
      ),
    );

    expect(service.typeName, ['_ferret', '_tcp', 'local']);
    expect(read?.deviceId, 'abcdefgh234567ab');
    expect(read?.name, 'Pixel 7 ✨');
    expect(read?.platform, Platform.PLATFORM_ANDROID);
    expect(read?.formFactor, FormFactor.FORM_FACTOR_PHONE);
    expect(read?.port, 50123);
    expect(read?.protocolVersion, 1);
  });

  test('refuses an instance whose id is not its name, or without one', () {
    MdnsInstance instance(Map<String, String> txt) => MdnsInstance(
      name: 'abcdefgh234567ab',
      address: InternetAddress('192.168.1.5'),
      port: 1,
      txt: txt,
    );

    expect(MdnsDiscovery.announceFrom(instance(const {})), isNull);
    expect(
      MdnsDiscovery.announceFrom(instance(const {'id': 'someoneelse234567'})),
      isNull,
    );
  });

  test('cuts a very long name so it fits a TXT entry', () {
    final service = MdnsDiscovery.serviceFor(
      _announce('abcdefgh234567ab', 'é' * 300),
    );

    expect(
      DnsRecord.txt(service.instanceName, service.txt, 1).data,
      isNotEmpty,
    );
  });

  test('two devices find each other, whoever started first', () async {
    final mac = join();
    final pixel = join();
    final seenByMac = <DiscoveredPeer>[];
    final seenByPixel = <DiscoveredPeer>[];
    mac.peers.listen(seenByMac.add);
    pixel.peers.listen(seenByPixel.add);

    await mac.start(_announce('macmacmacmacmac2', 'MacBook Pro'));
    await pixel.start(_announce('pixelpixelpixel2', 'Pixel 7', port: 40001));
    await Future.wait([mac.scan(), pixel.scan()]);

    expect(seenByMac.last.announce.name, 'Pixel 7');
    expect(seenByMac.last.port, 40001);
    expect(seenByMac.last.host, '192.168.1.11');
    expect(seenByPixel.last.deviceId, 'macmacmacmacmac2');
    expect({for (final peer in seenByMac) peer.deviceId}, hasLength(1));
  });

  test('a device that stops is reported as gone', () async {
    final mac = join();
    final pixel = join();
    await mac.start(_announce('macmacmacmacmac2', 'MacBook Pro'));
    await pixel.start(_announce('pixelpixelpixel2', 'Pixel 7'));
    await mac.scan();
    final gone = mac.departures.first;

    await pixel.stop();

    expect(await gone.timeout(const Duration(seconds: 1)), 'pixelpixelpixel2');
  });

  test('still finds others when the mDNS port could not be shared', () async {
    final mac = join();
    final phone = join(sharesPort: false);
    final seen = <DiscoveredPeer>[];
    phone.peers.listen(seen.add);

    await mac.start(_announce('macmacmacmacmac2', 'MacBook Pro'));
    await phone.start(_announce('pixelpixelpixel2', 'Pixel 7'));
    await phone.scan();

    expect(seen.last.deviceId, 'macmacmacmacmac2');
  });

  test('a new name replaces the old offer', () async {
    final mac = join();
    final pixel = join();
    final seen = <DiscoveredPeer>[];
    mac.peers.listen(seen.add);
    await mac.start(_announce('macmacmacmacmac2', 'MacBook Pro'));
    await pixel.start(_announce('pixelpixelpixel2', 'Pixel 7'));
    await mac.scan();

    await pixel.start(_announce('pixelpixelpixel2', 'Simon’s Pixel'));
    await mac.scan();

    expect(seen.last.announce.name, 'Simon’s Pixel');
  });
}
