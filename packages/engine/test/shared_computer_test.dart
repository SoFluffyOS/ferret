import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

void main() {
  final engines = <FerretEngine>[];

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  Future<FerretEngine> startEngine({
    required Discovery discovery,
    Platform platform = .PLATFORM_WINDOWS,
    int port = 0,
  }) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: 'Family PC',
        platform: platform,
        formFactor: .FORM_FACTOR_DESKTOP,
      ),
      discovery: discovery,
      port: port,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  test('the ports tried skip discovery and stay in a known range', () {
    expect(FerretEngine.candidatePorts(47640), [
      47640,
      for (var port = 47642; port <= 47649; port++) port,
    ]);
    expect(FerretEngine.candidatePorts(0), [0]);
  });

  test('a taken port moves to the next one in the range', () async {
    final taken = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    addTearDown(taken.close);

    final engine = await startEngine(
      discovery: _Bus().join(),
      port: taken.port,
    );

    expect(engine.port, isNot(taken.port));
    expect(
      FerretEngine.candidatePorts(taken.port).skip(1),
      contains(engine.port),
    );
    expect(engine.usesFallbackPort, isTrue);
  });

  test('a free preferred port is used as is', () async {
    final probe = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final free = probe.port;
    await probe.close();

    final engine = await startEngine(discovery: _Bus().join(), port: free);

    expect(engine.port, free);
    expect(engine.usesFallbackPort, isFalse);
  });

  test(
    'Ferret of another account on this computer is told apart from a phone',
    () async {
      final bus = _Bus();
      final anna = await startEngine(discovery: bus.join());
      final changes = anna.otherAccountsChanges.first;
      final ben = await startEngine(discovery: bus.join());
      await startEngine(discovery: bus.join(), platform: .PLATFORM_ANDROID);

      await changes.timeout(const Duration(seconds: 2));

      expect(anna.otherAccountsHere, {ben.identity.deviceId});
    },
  );

  test('a computer elsewhere on the network is not another account', () async {
    final bus = _Bus(host: '192.0.2.40');
    final anna = await startEngine(discovery: bus.join());
    await startEngine(discovery: bus.join());

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(anna.otherAccountsHere, isEmpty);
  });
}

class _Bus {
  _Bus({this.host = '127.0.0.1'});

  final String host;
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
      if (member == this) {
        continue;
      }

      member._peers.add(DiscoveredPeer(announce: announce, host: bus.host));
      if (member.self case final other?) {
        _peers.add(DiscoveredPeer(announce: other, host: bus.host));
      }
    }
  }

  @override
  Future<void> stop() async => self = null;
}
