import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

TrustedDevice _computer() => TrustedDevice(
  id: 'a1b2c3d4e5f60718',
  name: 'MacBook Pro',
  platform: .PLATFORM_MACOS,
  formFactor: .FORM_FACTOR_LAPTOP,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026, 11, 19),
);

WakeInfo _wake({String address = '192.168.1.20'}) => WakeInfo(
  interfaces: [
    WakeInterface(
      mac: [0x3c, 0x22, 0xfb, 0x01, 0x02, 0x03],
      address: address,
      broadcast: '192.168.1.255',
      link: .WAKE_LINK_WIRED,
      setting: .WAKE_SETTING_ON,
    ),
  ],
);

void main() {
  test('how to wake a computer survives saving and reading back', () {
    final saved = _computer().copyWith(wake: _wake()).toJson();

    final read = TrustedDevice.fromJson(saved);

    expect(read.wake, _wake());
  });

  test('a device saved before Wake-on-LAN has nothing to wake it by', () {
    final saved = _computer().toJson();

    expect(saved.containsKey('wake'), isFalse);
    expect(TrustedDevice.fromJson(saved).wake, isNull);
  });

  test('renaming and labelling keep how to wake it', () {
    final device = _computer().copyWith(wake: _wake());

    expect(device.withNickname('Office Mac').wake, _wake());
    expect(device.withSameNameTag('0718').wake, _wake());
    expect(device.copyWith(lastHost: '10.0.0.2').wake, _wake());
  });

  test('the trust store saves wake info only when it changed', () async {
    final store = TrustStore.memory();
    await store.save(_computer());
    final saves = <List<TrustedDevice>>[];
    final subscription = store.changes.listen(saves.add);

    await store.saveWake('a1b2c3d4e5f60718', _wake());
    await store.saveWake('a1b2c3d4e5f60718', _wake());
    await store.saveWake('a1b2c3d4e5f60718', _wake(address: '192.168.1.21'));
    await store.saveWake('unknown', _wake());
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(saves, hasLength(2));
    expect(
      store['a1b2c3d4e5f60718']?.wake?.interfaces.single.address,
      '192.168.1.21',
    );
  });
}
