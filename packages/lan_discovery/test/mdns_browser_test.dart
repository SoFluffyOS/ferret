import 'dart:async';

import 'package:lan_discovery/lan_discovery.dart';
import 'package:test/test.dart';

import 'support/memory_mdns.dart';

const _type = '_demo._tcp';

MdnsService _service(String instance, {int port = 4000, String name = 'One'}) =>
    MdnsService(
      type: _type,
      instance: instance,
      host: 'host-$instance',
      port: port,
      txt: {'n': name},
    );

void main() {
  late MemoryMdnsNetwork network;
  final advertisers = <MdnsAdvertiser>[];
  final browsers = <MdnsBrowser>[];

  setUp(() => network = MemoryMdnsNetwork());

  tearDown(() async {
    for (final browser in browsers) {
      await browser.stop();
    }

    for (final advertiser in advertisers) {
      await advertiser.stop();
    }

    browsers.clear();
    advertisers.clear();
  });

  Future<MdnsAdvertiser> advertise(MdnsService service) async {
    final advertiser = MdnsAdvertiser(
      service,
      reannounceEvery: null,
      socket: network.join(),
    );
    await advertiser.start();
    advertisers.add(advertiser);
    return advertiser;
  }

  MdnsBrowser browser({
    bool sharesPort = true,
    String? ignore,
    Duration collectFor = const Duration(milliseconds: 40),
  }) {
    final browser = MdnsBrowser(
      _type,
      collectFor: collectFor,
      ignore: ignore,
      socket: network.join(sharesPort: sharesPort),
    );
    browsers.add(browser);
    return browser;
  }

  test('finds a service that was already there by asking', () async {
    await advertise(_service('alpha', port: 4100, name: 'Alpha'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // The advertiser answers everyone at most once a second.
    final looking = browser(collectFor: const Duration(milliseconds: 1400));

    await looking.start();
    await looking.scan();

    final found = looking.instances.single;
    expect(found.name, 'alpha');
    expect(found.port, 4100);
    expect(found.txt, {'n': 'Alpha'});
    expect(found.address.address, '192.168.1.10');
  });

  test('hears a service that starts later, once', () async {
    final looking = browser();
    await looking.start();
    final appeared = <MdnsInstance>[];
    looking.appeared.listen(appeared.add);

    await advertise(_service('beta'));
    await looking.scan();
    await looking.scan();

    expect(appeared.map((instance) => instance.name), ['beta']);
  });

  test('forgets a service that says goodbye', () async {
    final advertiser = await advertise(_service('gamma'));
    final looking = browser();
    await looking.start();
    await looking.scan();
    final left = looking.left.first;

    await advertiser.stop();

    expect(await left.timeout(const Duration(seconds: 1)), 'gamma');
    expect(looking.instances, isEmpty);
  });

  test('gets answers straight back when the mDNS port is taken', () async {
    await advertise(_service('delta', port: 4200));
    final looking = browser(sharesPort: false);

    await looking.start();
    await looking.scan();

    expect(looking.instances.single.port, 4200);
  });

  test('leaves out its own instance and other service types', () async {
    await advertise(_service('mine'));
    await advertise(
      const MdnsService(
        type: '_other._tcp',
        instance: 'stranger',
        host: 'host-stranger',
        port: 1,
      ),
    );
    final looking = browser(ignore: 'MINE');

    await looking.start();
    await looking.scan();

    expect(looking.instances, isEmpty);
  });

  test('says again when a service changes its details', () async {
    final first = await advertise(_service('epsilon', name: 'Old name'));
    final looking = browser();
    await looking.start();
    await looking.scan();
    final appeared = <MdnsInstance>[];
    looking.appeared.listen(appeared.add);

    await first.stop();
    await advertise(_service('epsilon', name: 'New name'));
    await looking.scan();

    expect(appeared.last.txt['n'], 'New name');
  });

  test('drops an instance whose records ran out', () async {
    final link = network.join();
    final looking = browser();
    await looking.start();
    final left = looking.left.first;

    await link.multicast(
      (local) => DnsMessage(
        isResponse: true,
        answers: [
          DnsRecord.ptr(
            ['_demo', '_tcp', 'local'],
            ['brief', '_demo', '_tcp', 'local'],
            1,
          ),
          DnsRecord.srv(
            ['brief', '_demo', '_tcp', 'local'],
            ['host-brief', 'local'],
            4300,
            1,
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(looking.instances.single.name, 'brief');

    expect(await left.timeout(const Duration(seconds: 4)), 'brief');
  });
}
