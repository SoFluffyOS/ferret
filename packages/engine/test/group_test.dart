import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart' hide ForgottenDevice;
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

  Future<FerretEngine> startEngine(
    String name, {
    bool sharesPairings = true,
  }) async {
    final settings = MemorySettingsStore();
    if (!sharesPairings) {
      await settings.set(FerretEngine.sharePairingsKey, false);
    }

    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: settings,
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [_CopyFeature()],
      discovery: _SilentDiscovery(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<void> pair(FerretEngine asking, FerretEngine answering) async {
    final handle = await answering.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    offer
      ?..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await asking.pairWithOffer(offer ?? PairingOffer()), isA<Paired>());
  }

  bool connected(FerretEngine engine, List<FerretEngine> others) =>
      others.every(
        (other) => engine.sessionFor(other.identity.deviceId) != null,
      );

  test(
    'pairing once joins every device, and a copy reaches them all',
    () async {
      final mac = await startEngine('MacBook Pro');
      final pixel = await startEngine('Pixel 7');
      final tablet = await startEngine('Tablet');
      final joinedOnPixel = pixel.joins.first;
      final joinedOnTablet = tablet.joins.first;

      await pair(pixel, mac);
      await _until(() => connected(mac, [pixel]));
      await pair(tablet, mac);

      await _until(
        () =>
            connected(mac, [pixel, tablet]) &&
            connected(pixel, [mac, tablet]) &&
            connected(tablet, [mac, pixel]),
      );
      final tabletOnPixel = pixel.trustStore[tablet.identity.deviceId];
      expect(tabletOnPixel?.name, 'Tablet');
      expect(tabletOnPixel?.introducedBy, mac.identity.deviceId);
      expect(tabletOnPixel?.publicKey, tablet.identity.publicKey);
      expect((await joinedOnPixel).introducer.name, 'MacBook Pro');
      expect((await joinedOnTablet).device.name, 'Pixel 7');
      expect(mac.trustStore[pixel.identity.deviceId]?.introducedBy, isNull);

      await pixel.feature<_CopyFeature>()?.copy(42);

      await _until(
        () =>
            mac.feature<_CopyFeature>()?.received.contains(42) == true &&
            tablet.feature<_CopyFeature>()?.received.contains(42) == true,
      );
    },
  );

  test('the prompt names the devices that come along', () async {
    final mac = await startEngine('MacBook Pro');
    final pixel = await startEngine('Pixel 7');
    final tablet = await startEngine('Tablet');
    await pair(pixel, mac);
    await _until(() => connected(mac, [pixel]));

    final prompt = tablet.pairingPrompts.first;
    final outcome = mac.pairWithAddress(
      '127.0.0.1',
      tablet.port,
      onCode: (_) => true,
    );
    final shown = await prompt;
    expect(shown.alsoDevices, ['Pixel 7']);
    shown.accept();

    expect(await outcome, isA<Paired>());
    await _until(() => connected(tablet, [mac, pixel]));
  });

  test('a device that turned sharing off stays out of it', () async {
    final mac = await startEngine('MacBook Pro');
    final pixel = await startEngine('Pixel 7');
    final loner = await startEngine('Loner', sharesPairings: false);

    await pair(pixel, mac);
    await pair(loner, mac);
    await _until(() => connected(mac, [pixel, loner]));

    // The Mac vouches for it, the phone tries, and is told it isn't paired
    // there, so it lets go again.
    await _until(
      () => pixel.trustStore.forgottenOf(loner.identity.deviceId) != null,
    );
    await mac.setSharesPairings(true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(loner.trustStore.isTrusted(pixel.identity.deviceId), isFalse);
    expect(pixel.trustStore.isTrusted(loner.identity.deviceId), isFalse);
    expect(connected(mac, [pixel, loner]), isTrue);
  });

  test(
    'a device that was away learns of the new one when it is back',
    () async {
      final mac = await startEngine('MacBook Pro');
      final pixel = await startEngine('Pixel 7');
      final tablet = await startEngine('Tablet');
      await pair(pixel, mac);
      await _until(() => connected(mac, [pixel]));

      await pixel.stop();
      await pair(tablet, mac);
      await _until(() => connected(mac, [tablet]));
      expect(pixel.trustStore.isTrusted(tablet.identity.deviceId), isFalse);

      await pixel.start();

      await _until(
        () => connected(pixel, [mac, tablet]) && connected(tablet, [pixel]),
        timeout: const Duration(seconds: 10),
      );
    },
  );

  test('removing a device from all of them reaches every one', () async {
    final mac = await startEngine('MacBook Pro');
    final pixel = await startEngine('Pixel 7');
    final tablet = await startEngine('Tablet');
    await pair(pixel, mac);
    await _until(() => connected(mac, [pixel]));
    await pair(tablet, mac);
    await _until(
      () => connected(pixel, [mac, tablet]) && connected(tablet, [mac, pixel]),
    );

    await mac.unpair(tablet.identity.deviceId, everywhere: true);

    await _until(
      () =>
          !pixel.trustStore.isTrusted(tablet.identity.deviceId) &&
          tablet.trustStore.devices.isEmpty,
    );
    expect(mac.trustStore.isTrusted(pixel.identity.deviceId), isTrue);
    expect(pixel.trustStore.isTrusted(mac.identity.deviceId), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(pixel.trustStore.isTrusted(tablet.identity.deviceId), isFalse);
    expect(tablet.sessions, isEmpty);
  });

  test('forgetting a device here only keeps it on the others', () async {
    final mac = await startEngine('MacBook Pro');
    final pixel = await startEngine('Pixel 7');
    final tablet = await startEngine('Tablet');
    await pair(pixel, mac);
    await _until(() => connected(mac, [pixel]));
    await pair(tablet, mac);
    await _until(
      () => connected(pixel, [mac, tablet]) && connected(tablet, [mac, pixel]),
    );

    await pixel.unpair(tablet.identity.deviceId);
    await _until(() => !tablet.trustStore.isTrusted(pixel.identity.deviceId));

    // Sharing again, as on every reconnect, must not bring it back.
    await mac.setSharesPairings(true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(pixel.trustStore.isTrusted(tablet.identity.deviceId), isFalse);
    expect(tablet.trustStore.isTrusted(pixel.identity.deviceId), isFalse);
    expect(connected(mac, [pixel, tablet]), isTrue);
  });

  test('a device that was away drops what was removed meanwhile', () async {
    final mac = await startEngine('MacBook Pro');
    final pixel = await startEngine('Pixel 7');
    final tablet = await startEngine('Tablet');
    await pair(pixel, mac);
    await _until(() => connected(mac, [pixel]));
    await pair(tablet, mac);
    await _until(
      () => connected(pixel, [mac, tablet]) && connected(tablet, [mac, pixel]),
    );

    await pixel.stop();
    await mac.unpair(tablet.identity.deviceId, everywhere: true);
    expect(pixel.trustStore.isTrusted(tablet.identity.deviceId), isTrue);
    await pixel.start();

    await _until(
      () => !pixel.trustStore.isTrusted(tablet.identity.deviceId),
      timeout: const Duration(seconds: 10),
    );
    expect(mac.trustStore.isTrusted(tablet.identity.deviceId), isFalse);
  });

  test('pairing a removed device again brings it back everywhere', () async {
    final mac = await startEngine('MacBook Pro');
    final pixel = await startEngine('Pixel 7');
    final tablet = await startEngine('Tablet');
    await pair(pixel, mac);
    await _until(() => connected(mac, [pixel]));
    await pair(tablet, mac);
    await _until(() => connected(pixel, [mac, tablet]));
    await mac.unpair(tablet.identity.deviceId, everywhere: true);
    await _until(
      () =>
          !pixel.trustStore.isTrusted(tablet.identity.deviceId) &&
          tablet.trustStore.devices.isEmpty,
    );

    await pair(tablet, mac);

    await _until(
      () => connected(pixel, [mac, tablet]) && connected(tablet, [mac, pixel]),
    );
  });

  group('DeviceRoster', () {
    late TrustStore trustStore;
    late DeviceRoster roster;
    late TrustedDevice mac;

    Future<IntroducedDevice> introduced(
      String name, {
      DateTime? pairedAt,
    }) async {
      final identity = await DeviceIdentity.generate();
      return IntroducedDevice(
        id: identity.deviceId,
        name: name,
        staticPublicKey: identity.publicKey,
        host: '192.168.1.9',
        port: 47640,
        pairedAtMs: Int64(
          (pairedAt ?? DateTime(2026, 11, 18)).millisecondsSinceEpoch,
        ),
      );
    }

    setUp(() async {
      trustStore = await TrustStore.open(MemorySecretStore());
      roster = DeviceRoster(trustStore, 'thisdevice234567');
      final identity = await DeviceIdentity.generate();
      mac = TrustedDevice(
        id: identity.deviceId,
        name: 'MacBook Pro',
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_LAPTOP,
        publicKey: identity.publicKey,
        pairedAt: DateTime(2026, 11, 1),
      );
      await trustStore.save(mac);
    });

    test('takes in a device with the key its id stands for', () async {
      final pixel = await introduced('Pixel 7');

      final changes = await roster.apply(Introduce(devices: [pixel]), mac);

      expect(changes.joined.single.device.name, 'Pixel 7');
      expect(trustStore[pixel.id]?.introducedBy, mac.id);
      expect(trustStore[pixel.id]?.lastHost, '192.168.1.9');
    });

    test('drops an entry whose id does not come from its key', () async {
      final pixel = await introduced('Pixel 7');
      final other = await introduced('Other');
      final forged = pixel.deepCopy()..staticPublicKey = other.staticPublicKey;
      final short = pixel.deepCopy()..staticPublicKey = [1, 2, 3];

      final changes = await roster.apply(
        Introduce(devices: [forged, short]),
        mac,
      );

      expect(changes.joined, isEmpty);
      expect(trustStore.devices, hasLength(1));
    });

    test('never replaces the key of a device it already trusts', () async {
      final pixel = await introduced('Pixel 7');
      await roster.apply(Introduce(devices: [pixel]), mac);
      final renamed = pixel.deepCopy()..name = 'Impostor';

      final changes = await roster.apply(Introduce(devices: [renamed]), mac);

      expect(changes.joined, isEmpty);
      expect(trustStore[pixel.id]?.name, 'Pixel 7');
    });

    test('leaves itself and the introducer out', () async {
      final self = (await introduced('Me')).deepCopy()..id = 'thisdevice234567';
      final again = IntroducedDevice(
        id: mac.id,
        name: 'Mac again',
        staticPublicKey: mac.publicKey,
      );

      final changes = await roster.apply(
        Introduce(
          devices: [self, again],
          forgotten: [
            .new(id: mac.id, forgottenAtMs: Int64(1 << 50)),
            .new(id: 'thisdevice234567', forgottenAtMs: Int64(1 << 50)),
          ],
        ),
        mac,
      );

      expect(changes.joined, isEmpty);
      expect(changes.removed, isEmpty);
      expect(trustStore.isTrusted(mac.id), isTrue);
    });

    test('a forgotten device stays out until it is paired anew', () async {
      final pixel = await introduced(
        'Pixel 7',
        pairedAt: DateTime(2026, 11, 2),
      );
      await roster.apply(Introduce(devices: [pixel]), mac);

      final removed = await roster.apply(
        Introduce(
          devices: [pixel],
          forgotten: [
            .new(
              id: pixel.id,
              forgottenAtMs: Int64(
                DateTime(2026, 11, 3).millisecondsSinceEpoch,
              ),
            ),
          ],
        ),
        mac,
      );
      final stale = await roster.apply(Introduce(devices: [pixel]), mac);
      final fresh = await roster.apply(
        Introduce(
          devices: [
            pixel.deepCopy()
              ..pairedAtMs = Int64(
                DateTime(2026, 11, 4).millisecondsSinceEpoch,
              ),
          ],
        ),
        mac,
      );

      expect(removed.removed, [pixel.id]);
      expect(removed.joined, isEmpty);
      expect(stale.joined, isEmpty);
      expect(fresh.joined.single.device.id, pixel.id);
    });

    test('tells a device about the others, not about itself', () async {
      final pixel = await introduced('Pixel 7');
      await roster.apply(Introduce(devices: [pixel]), mac);
      await trustStore.forget(
        .new(id: 'gonegonegonegone', at: DateTime(2026), by: .everywhere),
      );
      await trustStore.forget(
        .new(id: 'onlyhereonlyhere', at: DateTime(2026), by: .here),
      );

      final toPixel = roster.introductionFor(pixel.id);

      expect(toPixel.devices.single.id, mac.id);
      expect(toPixel.devices.single.staticPublicKey, mac.publicKey);
      expect(toPixel.forgotten.single.id, 'gonegonegonegone');
    });
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

/// Stands in for clipboard sync: what one device copies goes to every
/// connected one.
class _CopyFeature extends Feature {
  final List<int> received = [];

  @override
  String get id => 'copy';

  Future<void> copy(int value) =>
      host.broadcast(id, Ping(sentAtMs: .new(value)));

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    final ping = payloadOf(envelope, Ping.new);
    if (ping != null) {
      received.add(ping.sentAtMs.toInt());
    }

    return null;
  }
}

/// Finds nobody, so devices only meet through pairing and introductions.
class _SilentDiscovery implements Discovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}
