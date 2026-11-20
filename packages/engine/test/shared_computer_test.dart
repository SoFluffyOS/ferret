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
    SecretStore? secrets,
    SameAccount? sameAccount,
  }) async {
    final engine = await FerretEngine.create(
      secrets: secrets ?? MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: 'Family PC',
        platform: platform,
        formFactor: .FORM_FACTOR_DESKTOP,
      ),
      discovery: discovery,
      port: port,
      sameAccount: sameAccount ?? SameAccount(listens: (_) async => false),
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

  group('what this same account runs is not another account', () {
    late Directory home;

    setUp(() async {
      home = await Directory.systemTemp.createTemp('ferret_same_account');
    });

    tearDown(() => home.delete(recursive: true));

    test('its ferret-cli, known by the identity it can read', () async {
      final cliSecrets = '${home.path}/cli/secrets';
      final bus = _Bus();
      final anna = await startEngine(
        discovery: bus.join(),
        sameAccount: SameAccount(
          siblingSecrets: [cliSecrets],
          listens: (_) async => false,
        ),
      );
      final changes = anna.otherAccountsChanges.first;
      final cli = await startEngine(
        discovery: bus.join(),
        secrets: FileSecretStore(cliSecrets),
      );
      final ben = await startEngine(discovery: bus.join());

      await changes.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(anna.otherAccountsHere, {ben.identity.deviceId});
      expect(anna.otherAccountsHere, isNot(contains(cli.identity.deviceId)));
    });

    test('a ferret-cli identity set up after the app started', () async {
      final cliSecrets = '${home.path}/cli/secrets';
      final sameAccount = SameAccount(
        siblingSecrets: [cliSecrets],
        listens: (_) async => false,
      );
      final cli = await DeviceIdentity.loadOrCreate(
        FileSecretStore(cliSecrets),
      );

      expect(
        await sameAccount.runs(_peerFrom(cli.deviceId, port: 47642)),
        isTrue,
      );
      expect(
        await sameAccount.runs(_peerFrom('SOMEONEELSE', port: 47643)),
        isFalse,
      );
    });

    test(
      'an unreadable identity counts as another account, as before',
      () async {
        final cliSecrets = Directory('${home.path}/cli/secrets')
          ..createSync(recursive: true);
        File('${cliSecrets.path}/secrets.json').writeAsStringSync('not json');
        final sameAccount = SameAccount(
          siblingSecrets: [cliSecrets.path, '${home.path}/missing'],
          listens: (_) async => throw const FileSystemException('no lsof'),
        );

        expect(
          await sameAccount.runs(_peerFrom('BEN', port: 47642)),
          isFalse,
        );
      },
    );

    test('a copy listening in this account, such as one started from '
        'another data folder', () async {
      final bus = _Bus();
      final anna = await startEngine(
        discovery: bus.join(),
        sameAccount: SameAccount(),
      );
      final copy = await startEngine(discovery: bus.join());

      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(anna.otherAccountsHere, isNot(contains(copy.identity.deviceId)));
    }, testOn: 'mac-os || linux');

    test(
      'a port this account listens on is seen, a closed one is not',
      () async {
        final listener = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
        final port = listener.port;

        expect(await SameAccount.listensHere(port), isTrue);

        await listener.close();
        expect(await SameAccount.listensHere(port), isFalse);
      },
      testOn: 'mac-os || linux',
    );
  });

  test('a computer elsewhere on the network is not another account', () async {
    final bus = _Bus(host: '192.0.2.40');
    final anna = await startEngine(discovery: bus.join());
    await startEngine(discovery: bus.join());

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(anna.otherAccountsHere, isEmpty);
  });
}

DiscoveredPeer _peerFrom(String deviceId, {required int port}) =>
    DiscoveredPeer(
      announce: Announce(
        deviceId: deviceId,
        port: port,
        platform: .PLATFORM_WINDOWS,
      ),
      host: '127.0.0.1',
    );

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
