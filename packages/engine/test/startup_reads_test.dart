import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

/// A slow phone's Keystore: every read waits, and the reads it was asked
/// for at once are counted.
class _SlowSecrets implements SecretStore {
  final MemorySecretStore _inner = MemorySecretStore();
  int _reading = 0;
  int mostAtOnce = 0;

  @override
  Future<String?> read(String key) async {
    _reading++;
    if (_reading > mostAtOnce) {
      mostAtOnce = _reading;
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
    _reading--;
    return _inner.read(key);
  }

  @override
  Future<void> write(String key, String value) => _inner.write(key, value);

  @override
  Future<void> delete(String key) => _inner.delete(key);
}

void main() {
  test('starting reads the key and the paired devices side by side', () async {
    final secrets = _SlowSecrets();
    final first = await FerretEngine.create(
      secrets: secrets,
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'Galaxy A12',
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
      ),
      features: const [],
      port: 0,
    );
    secrets.mostAtOnce = 0;

    final again = await FerretEngine.create(
      secrets: secrets,
      settings: MemorySettingsStore(),
      device: const LocalDevice(
        name: 'Galaxy A12',
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
      ),
      features: const [],
      port: 0,
    );

    expect(secrets.mostAtOnce, 3);
    expect(again.identity.deviceId, first.identity.deviceId);
  });

  test('a paired-devices list that fails to read still fails the start', () {
    expect(
      TrustStore.open(_Broken()),
      throwsA(isA<StateError>()),
    );
  });
}

class _Broken implements SecretStore {
  @override
  Future<String?> read(String key) async => throw StateError('keystore');

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}
