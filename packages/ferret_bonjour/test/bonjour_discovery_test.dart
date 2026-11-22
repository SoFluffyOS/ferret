import 'dart:async';

import 'package:ferret_bonjour/ferret_bonjour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

const _selfId = 'selfselfselfself';
const _pixelId = 'oucznlh4khwcsee2';

Announce _announce(String id, String name, {int port = 47640}) => Announce(
  protocolVersion: 1,
  deviceId: id,
  name: name,
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  port: port,
);

BonjourService _service(
  String id, {
  String name = 'Pixel 7',
  List<String> addresses = const ['192.168.1.87'],
  int port = 47640,
}) => BonjourService(
  name: id,
  port: port,
  txt: MdnsDiscovery.txtFor(_announce(id, name, port: port)),
  addresses: addresses,
);

void main() {
  late FakeBonjour bonjour;
  late BonjourDiscovery discovery;

  setUp(() {
    bonjour = FakeBonjour();
    discovery = BonjourDiscovery(
      backend: bonjour,
      repeatEvery: const Duration(milliseconds: 40),
      collectFor: Duration.zero,
    );
  });

  tearDown(() => discovery.stop());

  test('offers this device with only what its announce says', () async {
    await discovery.start(_announce(_selfId, 'MacBook Pro', port: 47651));

    final offer = bonjour.offers.single;
    expect(offer.name, _selfId);
    expect(offer.type, '_ferret._tcp');
    expect(offer.port, 47651);
    expect(offer.txt.keys, unorderedEquals(['id', 'v', 'p', 'f', 'n']));
    expect(offer.txt['id'], _selfId);
    expect(offer.txt['n'], 'MacBook Pro');
  });

  group('listening on demand (Android)', () {
    late BonjourDiscovery onDemand;

    setUp(() {
      onDemand = BonjourDiscovery(
        backend: bonjour,
        repeatEvery: const Duration(milliseconds: 40),
        collectFor: Duration.zero,
        listensOnDemand: true,
      );
    });

    tearDown(() => onDemand.stop());

    test('stops browsing and offering while nothing needs to listen, and '
        'starts both again when something does', () async {
      await onDemand.start(_announce(_selfId, 'Pixel 7'));
      expect(bonjour.browsers, hasLength(1));
      expect(bonjour.offers, hasLength(1));

      await onDemand.setListening(false);
      expect(bonjour.browsers.single.stopped, isTrue);
      expect(bonjour.offers.single.stopped, isTrue);

      await onDemand.setListening(true);
      expect(bonjour.browsers, hasLength(2));
      expect(bonjour.browsers.last.stopped, isFalse);
      expect(bonjour.offers.last.stopped, isFalse);
    });

    test('told before starting, it waits until something listens', () async {
      await onDemand.setListening(false);
      await onDemand.start(_announce(_selfId, 'Pixel 7'));
      expect(bonjour.browsers, isEmpty);
      expect(bonjour.offers, isEmpty);

      await onDemand.setListening(true);
      expect(bonjour.browsers, hasLength(1));
      expect(bonjour.offers, hasLength(1));
    });

    test('stays stopped after stop, whatever it is told', () async {
      await onDemand.start(_announce(_selfId, 'Pixel 7'));
      await onDemand.setListening(false);
      await onDemand.stop();
      await onDemand.setListening(true);
      expect(bonjour.browsers, hasLength(1));
    });
  });

  test('elsewhere it keeps running when told not to listen', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    await discovery.setListening(false);

    expect(bonjour.browsers.single.stopped, isFalse);
    expect(bonjour.offers.single.stopped, isFalse);
  });

  test('reads a found device from its TXT entries', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    final found = discovery.peers.first;

    bonjour.find(_service(_pixelId, name: 'Pixel 7 ✨', port: 50123));
    final peer = await found;

    expect(peer.deviceId, _pixelId);
    expect(peer.host, '192.168.1.87');
    expect(peer.port, 50123);
    expect(peer.announce.name, 'Pixel 7 ✨');
    expect(peer.announce.platform, Platform.PLATFORM_ANDROID);
    expect(peer.announce.formFactor, FormFactor.FORM_FACTOR_PHONE);
    expect(peer.announce.protocolVersion, 1);
  });

  test('takes the IPv4 address, never IPv6 or link-local', () {
    final peer = BonjourDiscovery.peerFrom(
      _service(
        _pixelId,
        addresses: [
          'fe80::1',
          '2402:800::5',
          '169.254.3.4',
          '10.0.0.7',
        ],
      ),
    );

    expect(peer?.host, '10.0.0.7');
    expect(
      BonjourDiscovery.peerFrom(_service(_pixelId, addresses: ['fe80::1'])),
      isNull,
    );
  });

  test('skips services that are not Ferret devices or contradict '
      'themselves', () {
    expect(
      BonjourDiscovery.peerFrom(
        const BonjourService(
          name: 'printer',
          port: 631,
          txt: {'rp': 'ipp'},
          addresses: ['192.168.1.9'],
        ),
      ),
      isNull,
    );
    expect(
      BonjourDiscovery.peerFrom(
        BonjourService(
          name: 'someoneelse12345',
          port: 47640,
          txt: MdnsDiscovery.txtFor(_announce(_pixelId, 'Pixel')),
          addresses: const ['192.168.1.9'],
        ),
      ),
      isNull,
    );
    expect(
      BonjourDiscovery.peerFrom(_service(_pixelId, port: 0)),
      isNull,
    );
  });

  test('ignores itself', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    final heard = <DiscoveredPeer>[];
    discovery.peers.listen(heard.add);

    bonjour.find(_service(_selfId, name: 'Mac'));
    await pump();

    expect(heard, isEmpty);
  });

  test('says a device left when the system lost it', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    bonjour.find(_service(_pixelId));
    await pump();
    final left = discovery.departures.first;

    bonjour.lose(_pixelId);

    expect(await left, _pixelId);
  });

  test('a device found twice is one device, passed on again while it '
      'stays', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    final heard = <DiscoveredPeer>[];
    discovery.peers.listen(heard.add);

    bonjour
      ..find(_service(_pixelId))
      ..find(_service(_pixelId, addresses: ['192.168.1.88']));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(heard.map((peer) => peer.deviceId).toSet(), {_pixelId});
    expect(heard.length, greaterThan(2));
    expect(heard.last.host, '192.168.1.88');
  });

  test('a lost device is no longer passed on again', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    bonjour.find(_service(_pixelId));
    await pump();
    bonjour.lose(_pixelId);
    await pump();
    final heard = <DiscoveredPeer>[];
    discovery.peers.listen(heard.add);

    await discovery.scan();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(heard, isEmpty);
  });

  test('a scan passes on what is already known', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    bonjour.find(_service(_pixelId));
    await pump();
    final again = discovery.peers.first;

    await discovery.scan();

    expect((await again).deviceId, _pixelId);
  });

  test('finding nobody may be a refusal; finding someone is not', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    expect(discovery.isBlocked, isTrue);

    bonjour.find(_service(_pixelId));
    await pump();

    expect(discovery.isBlocked, isFalse);
  });

  test('a denied browser reads as blocked', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    bonjour.find(_service(_pixelId));
    await pump();

    bonjour.fail(denied: true);
    await pump();

    expect(discovery.isBlocked, isTrue);
  });

  test('another failure is not called blocked', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    bonjour.find(_service(_pixelId));
    await pump();

    bonjour.fail(denied: false);
    await pump();

    expect(discovery.isBlocked, isFalse);
  });

  test('still looks when the offer is refused', () async {
    bonjour.refuseOffers = true;
    await discovery.start(_announce(_selfId, 'Mac'));
    final found = discovery.peers.first;

    bonjour.find(_service(_pixelId));

    expect((await found).deviceId, _pixelId);
  });

  test('a new name takes the old offer back first', () async {
    await discovery.start(_announce(_selfId, 'Mac'));
    await discovery.start(_announce(_selfId, 'Mac'));
    expect(bonjour.offers, hasLength(1));

    await discovery.start(_announce(_selfId, 'Studio'));

    expect(bonjour.offers, hasLength(2));
    expect(bonjour.offers.first.stopped, isTrue);
    expect(bonjour.offers.last.txt['n'], 'Studio');
  });

  test('stop takes the offer back and stops browsing', () async {
    await discovery.start(_announce(_selfId, 'Mac'));

    await discovery.stop();

    expect(bonjour.offers.single.stopped, isTrue);
    expect(bonjour.browsers.single.stopped, isTrue);
  });

  group('quiet', () {
    test('a quiet device browses but offers nothing', () async {
      await discovery.setAnnouncing(false);
      await discovery.start(_announce(_selfId, 'Mac'));
      final found = discovery.peers.first;

      bonjour.find(_service(_pixelId));

      expect(bonjour.offers, isEmpty);
      expect((await found).deviceId, _pixelId);
      expect(discovery.isAnnouncing, isFalse);
    });

    test('announcing again offers it, going quiet takes it back', () async {
      await discovery.setAnnouncing(false);
      await discovery.start(_announce(_selfId, 'Mac'));

      await discovery.setAnnouncing(true);
      expect(bonjour.offers.single.name, _selfId);

      await discovery.setAnnouncing(false);
      expect(bonjour.offers.single.stopped, isTrue);
      expect(bonjour.browsers.single.stopped, isFalse);
    });

    test('a restart while quiet stays quiet', () async {
      await discovery.setAnnouncing(false);
      await discovery.start(_announce(_selfId, 'Mac'));
      await discovery.stop();

      await discovery.start(_announce(_selfId, 'Mac'));

      expect(bonjour.offers, isEmpty);
    });

    test('the platform discovery passes quiet on to every way', () async {
      final announce = FakeAnnounce();
      final combined = CombinedDiscovery([
        announce,
        FallbackDiscovery(discovery, FakeAnnounce()),
      ]);

      await combined.setAnnouncing(false);
      await combined.start(_announce(_selfId, 'Mac'));

      expect(bonjour.offers, isEmpty);
      expect(combined.isAnnouncing, isFalse);
      await combined.stop();
    });
  });

  group('next to the multicast announce', () {
    test('an old device on the announce and a new one on Bonjour both '
        'arrive, and one device on both is one id', () async {
      final announce = FakeAnnounce();
      final combined = CombinedDiscovery([
        announce,
        FallbackDiscovery(discovery, FakeAnnounce()),
      ]);
      final heard = <DiscoveredPeer>[];
      combined.peers.listen(heard.add);
      await combined.start(_announce(_selfId, 'Mac'));

      announce.hear(_announce('oldoldoldoldold1', 'Old Pixel'), '192.168.1.5');
      bonjour.find(_service('newnewnewnewnew1', name: 'iPhone'));
      announce.hear(_announce(_pixelId, 'Pixel 7'), '192.168.1.87');
      bonjour.find(_service(_pixelId));
      await pump();

      final byId = {for (final peer in heard) peer.deviceId: peer};
      expect(byId.keys, {'oldoldoldoldold1', 'newnewnewnewnew1', _pixelId});
      expect(byId[_pixelId]?.host, '192.168.1.87');
      await combined.stop();
    });

    test('falls back to the second way when Bonjour cannot start', () async {
      bonjour.refuseBrowsing = true;
      final fallback = FakeAnnounce();
      final way = FallbackDiscovery(discovery, fallback);
      final found = way.peers.first;

      await way.start(_announce(_selfId, 'Mac'));
      fallback.hear(_announce(_pixelId, 'Pixel 7'), '192.168.1.87');

      expect(way.active, same(fallback));
      expect((await found).deviceId, _pixelId);
      await way.stop();
      expect(fallback.stopped, isTrue);
    });

    test('uses only Bonjour when it starts', () async {
      final fallback = FakeAnnounce();
      final way = FallbackDiscovery(discovery, fallback);

      await way.start(_announce(_selfId, 'Mac'));

      expect(way.active, same(discovery));
      expect(fallback.started, isFalse);
      await way.stop();
    });
  });
}

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 10));

class FakeOffer implements BonjourOffer {
  FakeOffer(this.name, this.type, this.port, this.txt);

  final String name;
  final String type;
  final int port;
  final Map<String, String> txt;
  bool stopped = false;
  final StreamController<BonjourFailed> _failures = .broadcast();

  @override
  Stream<BonjourFailed> get failures => _failures.stream;

  @override
  Future<void> stop() async => stopped = true;
}

class FakeBrowser implements BonjourBrowser {
  final StreamController<BonjourEvent> controller = .broadcast();
  bool stopped = false;

  @override
  Stream<BonjourEvent> get events => controller.stream;

  @override
  Future<void> stop() async => stopped = true;
}

class FakeBonjour implements BonjourBackend {
  final List<FakeOffer> offers = [];
  final List<FakeBrowser> browsers = [];
  bool refuseOffers = false;
  bool refuseBrowsing = false;

  void find(BonjourService service) =>
      browsers.last.controller.add(BonjourFound(service));

  void lose(String name) => browsers.last.controller.add(BonjourLost(name));

  void fail({required bool denied}) =>
      browsers.last.controller.add(BonjourFailed(denied: denied));

  @override
  Future<BonjourOffer> offer({
    required String name,
    required String type,
    required int port,
    required Map<String, String> txt,
  }) async {
    if (refuseOffers) {
      throw StateError('no offers');
    }

    final offer = FakeOffer(name, type, port, txt);
    offers.add(offer);
    return offer;
  }

  @override
  Future<BonjourBrowser> browse(String type) async {
    if (refuseBrowsing) {
      throw StateError('no Bonjour here');
    }

    final browser = FakeBrowser();
    browsers.add(browser);
    return browser;
  }
}

/// Stands in for the multicast announce.
class FakeAnnounce implements ActiveDiscovery {
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  bool started = false;
  bool stopped = false;

  void hear(Announce announce, String host) =>
      _peers.add(DiscoveredPeer(announce: announce, host: host));

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Stream<String> get departures => const Stream.empty();

  @override
  bool get isBlocked => false;

  @override
  Future<void> start(Announce self) async => started = true;

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> scan() async {}

  @override
  Future<void> stop() async => stopped = true;
}
