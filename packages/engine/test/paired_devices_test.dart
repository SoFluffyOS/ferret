import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

import 'support/quiet_bus.dart';

/// Whatever a feature keeps for a device goes once that device is no
/// longer paired, however it went, so pairing it again starts with
/// nothing allowed.
void main() {
  Future<TrustedDevice> phone(String name) async {
    final identity = await DeviceIdentity.generate();
    return TrustedDevice(
      id: identity.deviceId,
      name: name,
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: identity.publicKey,
      pairedAt: DateTime.utc(2026, 11),
    );
  }

  test('features hear the paired devices at start and when one goes, and '
      'drop what they kept for the others', () async {
    final secrets = MemorySecretStore();
    final settings = MemorySettingsStore();
    final kept = await phone('Pixel 7');
    final sold = await phone('Pixel 5');
    final before = await TrustStore.open(secrets);
    await before.save(kept);
    await before.save(sold);
    await settings.set('test.always', [kept.id, sold.id, 'gone-before']);
    await settings.set('test.choices', {kept.id: true, sold.id: true});
    await settings.set('test.other', 'left alone');

    final feature = _Grants();
    final engine = await FerretEngine.create(
      secrets: secrets,
      settings: settings,
      device: const LocalDevice(
        name: 'MacBook Air',
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [feature],
      discovery: QuietBus().join(),
      port: 0,
      networks: () async => const [],
      ownAddresses: () async => const {},
    );
    addTearDown(engine.stop);
    await engine.start();

    expect(feature.heard.last, {kept.id, sold.id});
    expect(settings.get<List<Object?>>('test.always'), [kept.id, sold.id]);

    await engine.unpair(sold.id);
    await pumpEventQueue();

    expect(feature.heard.last, {kept.id});
    expect(settings.get<List<Object?>>('test.always'), [kept.id]);
    expect(settings.get<Map<Object?, Object?>>('test.choices'), {
      kept.id: true,
    });
    expect(settings.get<String>('test.other'), 'left alone');
  });

  test('keepOnlyPaired writes nothing when nothing goes', () async {
    final settings = MemorySettingsStore({
      'a': ['x'],
      'b': {'x': 1},
    });
    final changes = <String>[];
    settings.changes.listen(changes.add);

    await settings.keepOnlyPaired(['a', 'b', 'missing'], {'x'});
    await pumpEventQueue();

    expect(changes, isEmpty);
  });
}

class _Grants extends Feature {
  final List<Set<String>> heard = [];

  @override
  String get id => 'grants';

  @override
  Future<void> onPairedDevices(Set<String> deviceIds) async {
    heard.add(deviceIds);
    await host.settings.keepOnlyPaired([
      'test.always',
      'test.choices',
    ], deviceIds);
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async => null;
}
