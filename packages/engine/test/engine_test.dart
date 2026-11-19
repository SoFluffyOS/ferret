import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

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
    String name, {
    List<Feature> features = const [],
  }) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: features,
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<PairingOutcome> pairByOffer(
    FerretEngine scanner,
    FerretEngine shower,
  ) async {
    final handle = await shower.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    expect(offer, isNotNull);
    offer!
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    return scanner.pairWithOffer(offer);
  }

  test(
    'pairing with a QR offer trusts both sides and opens a session',
    () async {
      final laptop = await startEngine('Laptop', features: [_EchoFeature()]);
      final phone = await startEngine('Phone', features: [_EchoFeature()]);

      final outcome = await pairByOffer(phone, laptop);

      expect(outcome, isA<Paired>());
      expect((outcome as Paired).device.name, 'Laptop');
      await _until(
        () => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty,
      );
      expect(laptop.trustStore.isTrusted(phone.identity.deviceId), isTrue);
      expect(phone.trustStore.isTrusted(laptop.identity.deviceId), isTrue);
      expect(laptop.sessions.single.remoteDevice?.name, 'Phone');
      expect(laptop.sessions.single.supports('echo'), isTrue);
    },
  );

  group('per-device access', () {
    test('a feature turned off for a device is gone on both sides', () async {
      final laptopEcho = _EchoFeature();
      final laptop = await startEngine('Laptop', features: [laptopEcho]);
      final phone = await startEngine('Phone', features: [_EchoFeature()]);
      await pairByOffer(phone, laptop);
      await _until(
        () => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty,
      );
      final phoneId = phone.identity.deviceId;

      await laptop.access.setAllowed(phoneId, 'echo', allowed: false);
      await _until(
        () =>
            phone.sessions.isNotEmpty &&
            !phone.sessions.single.supports('echo') &&
            laptop.sessions.isNotEmpty,
      );

      expect(laptopEcho.host.sessions, isEmpty);
      expect(laptopEcho.host.sessionFor(phoneId), isNull);
      await expectLater(
        laptop.sessions.single.send('echo', Ping()),
        throwsA(isA<RemoteErrorException>()),
      );
      await expectLater(
        phone.sessions.single.request('echo', Ping()),
        throwsA(
          isA<RemoteErrorException>().having(
            (error) => error.code,
            'code',
            ErrorCode.ERROR_CODE_UNSUPPORTED,
          ),
        ),
      );
    });

    test('turning it back on brings it back', () async {
      final laptopEcho = _EchoFeature();
      final laptop = await startEngine('Laptop', features: [laptopEcho]);
      final phone = await startEngine('Phone', features: [_EchoFeature()]);
      await pairByOffer(phone, laptop);
      await _until(() => phone.sessions.isNotEmpty);
      final phoneId = phone.identity.deviceId;

      await laptop.access.setAllowed(phoneId, 'echo', allowed: false);
      await _until(
        () =>
            phone.sessions.isNotEmpty &&
            !phone.sessions.single.supports('echo'),
      );
      await laptop.access.setAllowed(phoneId, 'echo', allowed: true);
      await _until(
        () =>
            phone.sessions.isNotEmpty &&
            phone.sessions.single.supports('echo') &&
            laptopEcho.host.sessions.isNotEmpty,
      );

      final reply = await phone.sessions.single.call('echo', Ping(), Pong.new);
      expect(reply, isA<Pong>());
    });

    test('forgetting a device drops what was chosen for it', () async {
      final laptop = await startEngine('Laptop', features: [_EchoFeature()]);
      final phone = await startEngine('Phone', features: [_EchoFeature()]);
      await pairByOffer(phone, laptop);
      final phoneId = phone.identity.deviceId;
      await laptop.access.setAllowed(phoneId, 'echo', allowed: false);

      await laptop.unpair(phoneId);
      await _until(() => laptop.access.blockedFor(phoneId).isEmpty);

      expect(
        laptop.settings.get<Map<String, Object?>>(DeviceAccess.blockedKey),
        isEmpty,
      );
    });
  });

  test('an offer works only once', () async {
    final laptop = await startEngine('Laptop');
    final phone = await startEngine('Phone');
    final tablet = await startEngine('Tablet');

    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText)!
      ..hosts.clear()
      ..hosts.add('127.0.0.1');

    expect(await phone.pairWithOffer(offer), isA<Paired>());
    final second = await tablet.pairWithOffer(offer);
    expect(second, isA<PairingFailed>());
    expect((second as PairingFailed).reason, PairingFailure.expired);
  });

  test('a forged offer key is refused before anything is sent', () async {
    final laptop = await startEngine('Laptop');
    final phone = await startEngine('Phone');

    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText)!
      ..hosts.clear()
      ..hosts.add('127.0.0.1')
      ..staticPublicKey = List.filled(32, 7);

    final outcome = await phone.pairWithOffer(offer);

    expect((outcome as PairingFailed).reason, PairingFailure.wrongDevice);
    expect(laptop.trustStore.devices, isEmpty);
  });

  test(
    'pairing by comparing codes shows the same code on both sides',
    () async {
      final laptop = await startEngine('Laptop');
      final phone = await startEngine('Phone');

      final prompt = laptop.pairingPrompts.first;
      String? phoneCode;
      final outcome = phone.pairWithAddress(
        '127.0.0.1',
        laptop.port,
        expectedDeviceId: laptop.identity.deviceId,
        onCode: (code) {
          phoneCode = code;
          return true;
        },
      );

      final shown = await prompt;
      expect(shown.device.name, 'Phone');
      expect(shown.code, phoneCode);
      expect(shown.code, matches(RegExp(r'^\d{6}$')));
      shown.accept();

      expect(await outcome, isA<Paired>());
      await _until(
        () => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty,
      );
    },
  );

  test('a rejected code comparison trusts no one', () async {
    final laptop = await startEngine('Laptop');
    final phone = await startEngine('Phone');

    unawaited(laptop.pairingPrompts.first.then((prompt) => prompt.reject()));
    final outcome = await phone.pairWithAddress(
      '127.0.0.1',
      laptop.port,
      onCode: (_) => true,
    );

    expect((outcome as PairingFailed).reason, PairingFailure.rejected);
    expect(laptop.trustStore.devices, isEmpty);
    expect(phone.trustStore.devices, isEmpty);
  });

  test('the asking side saying no trusts no one, even after a yes', () async {
    final laptop = await startEngine('Laptop');
    final phone = await startEngine('Phone');
    final decision = Completer<bool>();

    final prompt = laptop.pairingPrompts.first;
    final outcome = phone.pairWithAddress(
      '127.0.0.1',
      laptop.port,
      onCode: (_) => decision.future,
    );
    (await prompt).accept();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(laptop.trustStore.devices, isEmpty);

    decision.complete(false);

    expect(((await outcome) as PairingFailed).reason, PairingFailure.cancelled);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(laptop.trustStore.devices, isEmpty);
    expect(phone.trustStore.devices, isEmpty);
  });

  test('giving up on the asking side takes the prompt away', () async {
    final laptop = await startEngine('Laptop');
    final phone = await startEngine('Phone');
    final decision = Completer<bool>();

    final prompt = laptop.pairingPrompts.first;
    final outcome = phone.pairWithAddress(
      '127.0.0.1',
      laptop.port,
      onCode: (_) => decision.future,
    );
    final shown = await prompt;
    decision.complete(false);

    expect(await shown.answer, PairingAnswer.withdrawn);
    expect(((await outcome) as PairingFailed).reason, PairingFailure.cancelled);
  });

  test(
    'a device announcing through this computer and port is not listed',
    () async {
      final laptop = await startEngine('Laptop');
      final discovery = bus.members.last;
      final emulator = await DeviceIdentity.generate();
      final terminal = await DeviceIdentity.generate();

      DiscoveredPeer announce(DeviceIdentity device, String name, int port) =>
          DiscoveredPeer(
            announce: Announce(
              deviceId: device.deviceId,
              name: name,
              port: port,
            ),
            host: '127.0.0.1',
          );

      discovery._peers
        ..add(announce(emulator, 'Emulator', laptop.port))
        ..add(announce(terminal, 'Terminal', laptop.port + 1));

      await _until(() => laptop.nearby.isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        [for (final peer in laptop.nearby) peer.announce.name],
        [
          'Terminal',
        ],
      );
    },
  );

  test('a device other than the one found nearby is refused', () async {
    final laptop = await startEngine('Laptop');
    final phone = await startEngine('Phone');
    final stranger = await DeviceIdentity.generate();
    var asked = false;

    final outcome = await phone.pairWithAddress(
      '127.0.0.1',
      laptop.port,
      expectedDeviceId: stranger.deviceId,
      onCode: (_) => asked = true,
    );

    expect((outcome as PairingFailed).reason, PairingFailure.wrongDevice);
    expect(asked, isFalse);
  });

  test('a comparison without a commitment is turned down unasked', () async {
    final laptop = await startEngine('Laptop');
    final identity = await DeviceIdentity.generate();
    var prompted = false;
    laptop.pairingPrompts.listen((_) => prompted = true);

    final channel = await SecureChannel.initiate(
      await SocketConnection.connect('127.0.0.1', laptop.port),
      identity.keyPair,
    );
    final exchange = PairingExchange(channel);
    await exchange.send(
      PairingRequest(
        device: DeviceInfo(id: identity.deviceId, name: 'Old'),
      ),
    );
    final reply = await exchange.next(const Duration(seconds: 2));

    expect(
      PairingExchange.read(reply, PairingResponse.new)?.result,
      PairingResult.PAIRING_RESULT_REJECTED,
    );
    expect(prompted, isFalse);
    await exchange.close();
  });

  test(
    'a revealed nonce that breaks the commitment ends the pairing',
    () async {
      final laptop = await startEngine('Laptop');
      final identity = await DeviceIdentity.generate();
      var prompted = false;
      laptop.pairingPrompts.listen((_) => prompted = true);

      final channel = await SecureChannel.initiate(
        await SocketConnection.connect('127.0.0.1', laptop.port),
        identity.keyPair,
      );
      final exchange = PairingExchange(channel);
      await exchange.send(
        PairingRequest(
          device: DeviceInfo(id: identity.deviceId, name: 'Cheat'),
          commitment: await PairingCodes.commitment(PairingCodes.newNonce()),
        ),
      );
      final challenge = await exchange.next(const Duration(seconds: 2));
      expect(PairingExchange.read(challenge, PairingChallenge.new), isNotNull);
      await exchange.send(PairingReveal(nonce: PairingCodes.newNonce()));
      final reply = await exchange.next(const Duration(seconds: 2));

      expect(
        PairingExchange.read(reply, PairingResponse.new)?.result,
        PairingResult.PAIRING_RESULT_BAD_PROOF,
      );
      expect(prompted, isFalse);
      expect(laptop.trustStore.devices, isEmpty);
      await exchange.close();
    },
  );

  test('the code depends on both nonces, not only on the handshake', () async {
    final hash = List<int>.filled(32, 9);
    final first = await PairingCodes.comparisonCode(
      hash,
      requesterNonce: List.filled(16, 1),
      answererNonce: List.filled(16, 2),
    );
    final otherAnswer = await PairingCodes.comparisonCode(
      hash,
      requesterNonce: List.filled(16, 1),
      answererNonce: List.filled(16, 3),
    );
    final swapped = await PairingCodes.comparisonCode(
      hash,
      requesterNonce: List.filled(16, 2),
      answererNonce: List.filled(16, 1),
    );

    expect({first, otherAnswer, swapped}, hasLength(3));
  });

  test(
    'features answer requests, and unknown features say unsupported',
    () async {
      final laptop = await startEngine('Laptop', features: [_EchoFeature()]);
      final phone = await startEngine('Phone', features: [_EchoFeature()]);
      await pairByOffer(phone, laptop);
      await _until(
        () => phone.sessions.isNotEmpty && laptop.sessions.isNotEmpty,
      );

      final session = phone.sessions.single;
      final pong = await session.call(
        'echo',
        Ping(sentAtMs: .new(7)),
        Pong.new,
      );
      expect(pong.pingSentAtMs.toInt(), 7);

      await expectLater(
        session.request('nope', Ping()),
        throwsA(
          isA<RemoteErrorException>().having(
            (error) => error.code,
            'code',
            ErrorCode.ERROR_CODE_UNSUPPORTED,
          ),
        ),
      );
    },
  );

  test('an unpaired device cannot open a session', () async {
    final laptop = await startEngine('Laptop', features: [_EchoFeature()]);
    final stranger = await startEngine('Stranger');

    await stranger.connect('127.0.0.1', laptop.port);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(laptop.sessions, isEmpty);
    expect(stranger.sessions, isEmpty);
  });

  test('unpairing removes trust on both sides', () async {
    final laptop = await startEngine('Laptop');
    final phone = await startEngine('Phone');
    await pairByOffer(phone, laptop);
    await _until(() => laptop.sessions.isNotEmpty);

    await laptop.unpair(phone.identity.deviceId);

    await _until(() => !phone.trustStore.isTrusted(laptop.identity.deviceId));
    expect(laptop.trustStore.devices, isEmpty);
    expect(phone.sessions, isEmpty);
  });

  test('a dropped session reconnects', () async {
    final laptop = await startEngine('Laptop');
    final phone = await startEngine('Phone');
    await pairByOffer(phone, laptop);
    await _until(() => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty);

    final first = laptop.sessions.single;
    await first.channel.connection.close();

    await _until(
      () =>
          laptop.sessions.length == 1 &&
          laptop.sessions.single != first &&
          phone.sessions.length == 1,
      timeout: const Duration(seconds: 10),
    );
    expect(phone.sessions.single.isClosed, isFalse);
  });

  test(
    'discovery connects paired devices that both dial at once to one session',
    () async {
      final laptop = await startEngine('Laptop');
      final phone = await startEngine('Phone');
      await pairByOffer(phone, laptop);
      await _until(
        () => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty,
      );

      await Future.wait([
        laptop.connect('127.0.0.1', phone.port),
        phone.connect('127.0.0.1', laptop.port),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(laptop.sessions, hasLength(1));
      expect(phone.sessions, hasLength(1));
      expect(
        laptop.sessions.single.initiatorDeviceId,
        phone.sessions.single.initiatorDeviceId,
      );
    },
  );

  test('renaming takes effect right away and is saved', () async {
    final laptop = await startEngine('Laptop');

    await laptop.rename('  Desk Mac  ');

    expect(laptop.device.name, 'Desk Mac');
    expect(laptop.localDevice.name, 'Desk Mac');
    expect(laptop.settings.get<String>('device.name'), 'Desk Mac');
  });

  test('device ids are 16 base32 characters', () async {
    final identity = await DeviceIdentity.generate();

    expect(identity.deviceId, matches(RegExp(r'^[a-z2-7]{16}$')));
    expect(
      DeviceIdentity.format(identity.deviceId),
      matches(RegExp(r'^[a-z2-7]{4}(-[a-z2-7]{4}){3}$')),
    );
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

class _EchoFeature extends Feature {
  @override
  String get id => 'echo';

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    final ping = payloadOf(envelope, Ping.new);
    if (ping == null) {
      return null;
    }

    return Pong(pingSentAtMs: ping.sentAtMs);
  }
}

/// Discovery over an in-memory bus, so tests don't need multicast.
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
