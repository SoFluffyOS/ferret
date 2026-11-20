import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

const _iphoneId = 'abcdabcdabcdabcd';

void main() {
  late _PeerDiscovery discovery;
  late FerretEngine engine;

  setUp(() async {
    discovery = _PeerDiscovery();
    engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'Pixel 7',
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
      ),
      discovery: discovery,
      port: 0,
    );
    await engine.trustStore.save(
      TrustedDevice(
        id: _iphoneId,
        name: 'iPhone',
        platform: .PLATFORM_IOS,
        formFactor: .FORM_FACTOR_PHONE,
        publicKey: Uint8List(32),
        pairedAt: DateTime(2026),
      ),
    );
    await engine.start();
  });

  tearDown(() => engine.stop());

  test('a paired device that was never heard is not heard', () {
    expect(engine.devices.single.isHeard, isFalse);
  });

  test('a paired device heard yet not connected says so', () async {
    final changes = engine.deviceChanges.first;

    discovery.hear(_iphoneId);
    final devices = await changes.timeout(const Duration(seconds: 5));

    expect(devices.single.isHeard, isTrue);
    expect(devices.single.isConnected, isFalse);
  });

  test('its goodbye on the network ends it', () async {
    discovery.hear(_iphoneId);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    discovery.leave(_iphoneId);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(engine.devices.single.isHeard, isFalse);
  });
}

class _PeerDiscovery implements ActiveDiscovery {
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  final StreamController<String> _departures = .broadcast();

  /// An announce from an address where nothing answers.
  void hear(String deviceId) => _peers.add(
    DiscoveredPeer(
      announce: Announce(
        protocolVersion: protocolVersion,
        deviceId: deviceId,
        name: 'iPhone',
        port: 9,
      ),
      host: '192.0.2.10',
    ),
  );

  void leave(String deviceId) => _departures.add(deviceId);

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Stream<String> get departures => _departures.stream;

  @override
  bool get isBlocked => false;

  @override
  Future<void> scan() async {}

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}
