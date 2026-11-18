import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';
import 'package:protocol/notifications.dart';

PhoneStatus _phone({
  MirrorSettings? settings,
  bool unreachable = false,
  bool online = true,
  bool sends = true,
}) => PhoneStatus(
  deviceId: 'phone',
  name: 'Pixel 9',
  settings: settings,
  unreachable: unreachable,
  online: online,
  sends: sends,
);

void main() {
  test('an offline phone is offline whatever it said before', () {
    expect(
      _phone(online: false, settings: MirrorSettings(enabled: true)).state,
      PhoneState.offline,
    );
  });

  test('a phone that does not offer mirroring counts as off', () {
    expect(_phone(sends: false).state, PhoneState.off);
  });

  test('settings decide between off, access off and mirroring', () {
    expect(_phone().state, PhoneState.checking);
    expect(_phone(unreachable: true).state, PhoneState.unreachable);
    expect(_phone(settings: MirrorSettings()).state, PhoneState.off);
    expect(
      _phone(settings: MirrorSettings(enabled: true)).state,
      PhoneState.accessOff,
    );
    expect(
      _phone(
        settings: MirrorSettings(enabled: true, accessGranted: true),
      ).state,
      PhoneState.mirroring,
    );
  });
}
