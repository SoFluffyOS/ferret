import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

import 'support/fakes.dart';

void main() {
  late _Bus bus;
  final engines = <FerretEngine>[];

  setUp(() => bus = _Bus());

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  Future<FerretEngine> startEngine(
    String name,
    HandoffFeature feature, {
    Map<String, Object?>? settings,
  }) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(settings),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [feature],
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<void> pair(FerretEngine scanner, FerretEngine shower) async {
    final handle = await shower.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The offer did not parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await scanner.pairWithOffer(offer), isA<Paired>());
  }

  Future<void> connected(List<FerretEngine> all, int peers) => _until(
    () => all.every(
      (engine) =>
          engine.sessions.length == peers &&
          engine.sessions.every(
            (session) => session.supports(HandoffFeature.featureId),
          ),
    ),
  );

  test('an explicit send opens on the other device', () async {
    final macOpener = FakeOpener();
    final phone = await startEngine(
      'Phone',
      HandoffFeature(opener: FakeOpener()),
    );
    final mac = await startEngine('Mac', HandoffFeature(opener: macOpener));
    await pair(phone, mac);
    await connected([phone, mac], 1);
    final phoneHandoff = phone.feature<HandoffFeature>();

    final outcome = await phoneHandoff?.sendTo(
      mac.identity.deviceId,
      webActivity('page', title: 'Ferrets'),
    );

    expect(outcome, SendOutcome.opened);
    expect(macOpener.opened.single.title, 'Ferrets');
    expect(macOpener.opened.single.sourceDeviceId, phone.identity.deviceId);
    expect(phoneHandoff?.timeline.single.peer.name, 'Mac');
    expect(
      mac.feature<HandoffFeature>()?.timeline.single.peer.name,
      'Phone',
    );
  });

  test('with automatic opening off the send waits as a suggestion', () async {
    final macOpener = FakeOpener();
    final phone = await startEngine('Phone', HandoffFeature());
    final mac = await startEngine(
      'Mac',
      HandoffFeature(opener: macOpener),
      settings: {HandoffSettings.openAutomatically: false},
    );
    await pair(phone, mac);
    await connected([phone, mac], 1);
    final macHandoff = mac.feature<HandoffFeature>();
    final arrival = macHandoff?.arrivals.first;

    final outcome = await phone.feature<HandoffFeature>()?.sendTo(
      mac.identity.deviceId,
      webActivity('page'),
    );

    expect(outcome, SendOutcome.suggested);
    expect((await arrival)?.from.name, 'Phone');
    expect(macOpener.opened, isEmpty);
    expect(macHandoff?.suggestions.single.isExplicit, isTrue);
  });

  test('a published activity is a suggestion and can be withdrawn', () async {
    final phone = await startEngine('Phone', HandoffFeature());
    final mac = await startEngine('Mac', HandoffFeature());
    await pair(phone, mac);
    await connected([phone, mac], 1);
    final phoneHandoff = phone.feature<HandoffFeature>();
    final macHandoff = mac.feature<HandoffFeature>();

    expect(await phoneHandoff?.publish(webActivity('page')), 1);
    await _until(() => macHandoff?.suggestions.isNotEmpty ?? false);
    expect(macHandoff?.suggestions.single.from.name, 'Phone');

    await phoneHandoff?.clearPublished();
    await _until(() => macHandoff?.suggestions.isEmpty ?? false);
  });

  test('passive activities go only where the user is active', () async {
    final phone = await startEngine('Phone', HandoffFeature());
    final mac = await startEngine('Mac', HandoffFeature());
    final tablet = await startEngine('Tablet', HandoffFeature());
    await pair(phone, mac);
    await pair(phone, tablet);
    await _until(() => phone.sessions.length == 2);
    await connected([mac, tablet], 1);

    await mac.updatePresence(Presence(userActive: true, batteryPercent: -1));
    await _until(
      () =>
          phone.sessionFor(mac.identity.deviceId)?.remotePresence.userActive ??
          false,
    );

    expect(await phone.feature<HandoffFeature>()?.publish(webActivity('p')), 1);
    await _until(
      () => mac.feature<HandoffFeature>()?.suggestions.isNotEmpty ?? false,
    );
    expect(tablet.feature<HandoffFeature>()?.suggestions, isEmpty);
  });
}

Future<void> _until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _Bus {
  final List<_BusDiscovery> members = [];

  Discovery join() {
    final member = _BusDiscovery(this);
    members.add(member);
    return member;
  }
}

class _BusDiscovery implements Discovery {
  _BusDiscovery(this.bus);

  final _Bus bus;
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  Announce? self;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Future<void> start(Announce self) async {
    this.self = self;
    await announceNow();
  }

  @override
  Future<void> announceNow() async {
    final announce = self;
    if (announce == null) {
      return;
    }

    for (final member in bus.members) {
      if (member != this) {
        member._peers.add(
          DiscoveredPeer(announce: announce, host: '127.0.0.1'),
        );
      }
    }
  }

  @override
  Future<void> stop() async => self = null;
}
