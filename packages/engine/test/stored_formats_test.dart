import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

/// What older builds saved still reads after an update.
void main() {
  test('a paired device saved before nicknames and introductions', () {
    final device = TrustedDevice.fromJson({
      'id': 'a1b2c3d4e5f60718',
      'name': 'Pixel 7',
      'platform': 1,
      'form_factor': 1,
      'public_key': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      'paired_at': 1700000000000,
    });

    expect(device.name, 'Pixel 7');
    expect(device.nickname, isNull);
    expect(device.lastSeen, isNull);
    expect(device.introducedBy, isNull);
  });

  test('per-device access missing or in an unknown shape allows all', () {
    final missing = DeviceAccess(MemorySettingsStore());
    final odd = DeviceAccess(
      MemorySettingsStore({DeviceAccess.blockedKey: 'clipboard'}),
    );

    expect(missing.blockedFor('a1'), isEmpty);
    expect(odd.blockedFor('a1'), isEmpty);
  });
}
