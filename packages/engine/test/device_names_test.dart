import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

class _NamesHost implements FeatureHost {
  _NamesHost(this.trustStore);

  @override
  final TrustStore trustStore;

  @override
  Session? sessionFor(String deviceId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

TrustedDevice _device(String id, String name, {String? nickname}) =>
    TrustedDevice(
      id: id,
      name: name,
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: Uint8List(32),
      pairedAt: DateTime(2026, 11),
      nickname: nickname,
    );

void main() {
  late MemorySecretStore secrets;
  late TrustStore store;

  setUp(() async {
    secrets = MemorySecretStore();
    store = await TrustStore.open(secrets);
  });

  test('two devices with the same name are told apart by their ids', () async {
    await store.save(_device('a1b2c3d4e5f60718', 'Pixel 7'));
    await store.save(_device('99aa88bb77cc3f2a', 'pixel 7'));
    await store.save(_device('1111222233334444', 'iPad'));

    expect(store['a1b2c3d4e5f60718']?.name, 'Pixel 7 (0718)');
    expect(store['99aa88bb77cc3f2a']?.name, 'pixel 7 (3F2A)');
    expect(store['1111222233334444']?.name, 'iPad');
    expect(
      [for (final device in store.devices) device.ownName],
      ['Pixel 7', 'pixel 7', 'iPad'],
    );
  });

  test('a nickname replaces the name here and ends the clash', () async {
    await store.save(_device('a1b2c3d4e5f60718', 'Pixel 7'));
    await store.save(_device('99aa88bb77cc3f2a', 'Pixel 7'));

    await store.rename('99aa88bb77cc3f2a', '  Old Pixel  ');

    expect(store['99aa88bb77cc3f2a']?.name, 'Old Pixel');
    expect(store['a1b2c3d4e5f60718']?.name, 'Pixel 7');
  });

  test('a blank nickname or the own name clears it', () async {
    await store.save(_device('a1', 'iPhone', nickname: 'Work iPhone'));

    await store.rename('a1', ' ');
    expect(store['a1']?.name, 'iPhone');

    await store.rename('a1', 'Work');
    await store.rename('a1', 'iPhone');
    expect(store['a1']?.nickname, isNull);
  });

  test('nicknames are kept on disk and survive a new own name', () async {
    await store.save(_device('a1', 'iPhone'));
    await store.rename('a1', 'Work iPhone');
    final saved = store['a1'];
    if (saved == null) {
      fail('device missing');
    }

    await store.save(saved.copyWith(name: 'iPhone 16'));
    final reopened = await TrustStore.open(secrets);

    expect(reopened['a1']?.name, 'Work iPhone');
    expect(reopened['a1']?.ownName, 'iPhone 16');
  });

  test('the tag is never saved as part of the name', () async {
    await store.save(_device('a1b2c3d4e5f60718', 'Pixel 7'));
    await store.save(_device('99aa88bb77cc3f2a', 'Pixel 7'));
    final tagged = store['a1b2c3d4e5f60718'];
    if (tagged == null) {
      fail('device missing');
    }

    await store.save(tagged.copyWith(lastHost: '10.0.0.2'));
    await store.remove('99aa88bb77cc3f2a');

    expect(store['a1b2c3d4e5f60718']?.name, 'Pixel 7');
    expect(store['a1b2c3d4e5f60718']?.toJson()['name'], 'Pixel 7');
  });

  test('other devices hear the own name, never the nickname', () async {
    await store.save(_device('a1b2c3d4e5f60718', 'Pixel 7'));
    await store.save(_device('99aa88bb77cc3f2a', 'Pixel 7'));
    await store.rename('a1b2c3d4e5f60718', 'My Pixel');

    final introduce = DeviceRoster(store, 'me').introductionFor('someone');

    expect(
      [for (final device in introduce.devices) device.name],
      ['Pixel 7', 'Pixel 7'],
    );
  });

  test('features read the same name the device list shows', () async {
    await store.save(_device('a1b2c3d4e5f60718', 'Pixel 7'));
    await store.save(_device('99aa88bb77cc3f2a', 'Pixel 7'));
    await store.save(_device('1111222233334444', 'iPhone'));
    await store.rename('1111222233334444', 'Work iPhone');
    final host = _NamesHost(store);

    expect(host.displayNameOf('a1b2c3d4e5f60718'), 'Pixel 7 (0718)');
    expect(host.displayNameOf('1111222233334444'), 'Work iPhone');
    expect(host.displayNameOf('unknown'), 'unknown');
  });
}
