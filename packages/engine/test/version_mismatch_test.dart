import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

DeviceInfo _info(int newest, {int oldest = 0, String app = ''}) => DeviceInfo(
  protocolVersion: newest,
  oldestProtocolVersion: oldest,
  appVersion: app,
);

void main() {
  group('between', () {
    test('the same version, or overlapping ranges, talk', () {
      expect(VersionMismatch.between(_info(1), _info(1)), isNull);
      expect(VersionMismatch.between(_info(3, oldest: 1), _info(1)), isNull);
      expect(VersionMismatch.between(_info(2), _info(3, oldest: 2)), isNull);
    });

    test('an app from before the oldest version field speaks only its own', () {
      expect(VersionMismatch.between(_info(1), _info(0)), isNull);
      expect(
        VersionMismatch.between(_info(2), _info(1))?.update,
        UpdateNeeded.otherDevice,
      );
    });

    test('the side whose newest is too old is the one to update', () {
      final otherOld = VersionMismatch.between(
        _info(3, oldest: 2),
        _info(1, app: '0.1.0'),
      );
      final thisOld = VersionMismatch.between(_info(1), _info(3, oldest: 2));

      expect(otherOld?.update, UpdateNeeded.otherDevice);
      expect(otherOld?.remoteProtocol, 1);
      expect(otherOld?.remoteAppVersion, '0.1.0');
      expect(thisOld?.update, UpdateNeeded.thisDevice);
      expect(thisOld?.remoteProtocol, 3);
    });
  });

  group('engines', () {
    final engines = <FerretEngine>[];

    tearDown(() async {
      for (final engine in engines) {
        await engine.stop();
      }

      engines.clear();
    });

    Future<FerretEngine> start(
      String name, {
      int newest = protocolVersion,
      int oldest = oldestProtocolVersion,
      Discovery? discovery,
      SecretStore? secrets,
    }) async {
      final engine = await FerretEngine.create(
        secrets: secrets ?? MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: LocalDevice(
          name: name,
          platform: .PLATFORM_MACOS,
          formFactor: .FORM_FACTOR_LAPTOP,
          appVersion: '$newest.0.0',
          newestProtocol: newest,
          oldestProtocol: oldest,
        ),
        discovery: discovery ?? _PeerDiscovery(),
        port: 0,
      );
      await engine.start();
      engines.add(engine);
      return engine;
    }

    Future<PairingOffer> offerOf(FerretEngine shower) async {
      final handle = await shower.createPairingOffer();
      final offer = PairingCodes.parseOffer(handle.qrText);
      if (offer == null) {
        fail('The offer did not parse');
      }

      return offer
        ..hosts.clear()
        ..hosts.add('127.0.0.1')
        ..port = shower.port;
    }

    /// Pairs as two devices did before one of them updated: the offer
    /// says nothing about versions, as the first builds' offers didn't.
    Future<void> pair(FerretEngine scanner, FerretEngine shower) async {
      final offer = await offerOf(shower)
        ..clearProtocolVersion()
        ..clearOldestProtocolVersion();
      expect(await scanner.pairWithOffer(offer), isA<Paired>());
    }

    test('a QR code from a Ferret too new says so before pairing', () async {
      final mac = await start('MacBook', newest: 2, oldest: 2);
      final phone = await start('Pixel 7');

      final outcome = await phone.pairWithOffer(await offerOf(mac));

      expect(outcome, isA<PairingFailed>());
      final failed = outcome as PairingFailed;
      expect(failed.reason, PairingFailure.updateThisDevice);
      expect(failed.detail, 'MacBook');
      expect(phone.devices, isEmpty);
    });

    test('a QR code from a Ferret too old asks to update it', () async {
      final mac = await start('MacBook', newest: 2, oldest: 2);
      final phone = await start('Pixel 7');

      final outcome = await mac.pairWithOffer(await offerOf(phone));

      expect(
        (outcome as PairingFailed).reason,
        PairingFailure.updateOtherDevice,
      );
    });

    test('overlapping versions pair from a QR code', () async {
      final mac = await start('MacBook', newest: 2);
      final phone = await start('Pixel 7');

      expect(await phone.pairWithOffer(await offerOf(mac)), isA<Paired>());
    });

    test('both sides say which one needs an update, and stay apart', () async {
      final mac = await start('MacBook', newest: 2, oldest: 2);
      final phone = await start('Pixel 7');

      await pair(phone, mac);
      await _until(
        () =>
            mac.devices.single.versionMismatch != null &&
            phone.devices.single.versionMismatch != null,
      );

      final onMac = mac.devices.single;
      final onPhone = phone.devices.single;
      expect(onMac.versionMismatch?.update, UpdateNeeded.otherDevice);
      expect(onMac.versionMismatch?.remoteAppVersion, '1.0.0');
      expect(onMac.isConnected, isFalse);
      expect(onMac.isReconnecting, isFalse);
      expect(onMac.device.lastSeen, isNotNull);
      expect(onPhone.versionMismatch?.update, UpdateNeeded.thisDevice);
      expect(mac.sessions, isEmpty);
      expect(phone.sessions, isEmpty);
    });

    test('the same version announced again is not dialed again', () async {
      final discovery = _PeerDiscovery();
      final mac = await start('MacBook', newest: 2, oldest: 2);
      final phone = await start('Pixel 7', discovery: discovery);
      await pair(phone, mac);
      await _until(() => phone.devices.single.versionMismatch != null);
      var handshakes = 0;
      final watching = mac.deviceChanges.listen((_) => handshakes++);

      discovery.hear(mac, protocolVersion: 2);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(handshakes, 0);
      expect(phone.devices.single.versionMismatch, isNotNull);
      await watching.cancel();
    });

    test('a device that updated is dialed and connects', () async {
      final discovery = _PeerDiscovery();
      final phoneSecrets = MemorySecretStore();
      final mac = await start(
        'MacBook',
        newest: 2,
        oldest: 2,
        discovery: discovery,
      );
      final oldPhone = await start('Pixel 7', secrets: phoneSecrets);
      await pair(oldPhone, mac);
      await _until(() => mac.devices.single.versionMismatch != null);

      await oldPhone.stop();
      final phone = await start(
        'Pixel 7',
        newest: 2,
        oldest: 1,
        secrets: phoneSecrets,
      );
      discovery.hear(phone, protocolVersion: 2);

      await _until(
        () =>
            mac.devices.single.isConnected &&
            mac.devices.single.versionMismatch == null,
      );
      expect(phone.devices.single.versionMismatch, isNull);
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

class _PeerDiscovery implements Discovery {
  final StreamController<DiscoveredPeer> _peers = .broadcast();

  void hear(FerretEngine engine, {required int protocolVersion}) => _peers.add(
    DiscoveredPeer(
      announce: Announce(
        protocolVersion: protocolVersion,
        deviceId: engine.identity.deviceId,
        name: engine.device.name,
        port: engine.port,
      ),
      host: '127.0.0.1',
    ),
  );

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}
