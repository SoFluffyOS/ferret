import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:wake/wake.dart';

import 'helpers/fakes.dart';

void main() {
  test('a wired card with Wake-on-LAN on is ready', () {
    expect(WakeReadiness.of(wiredWake()), WakeReadiness.ready);
  });

  test('a wired card says what it knows', () {
    expect(
      WakeReadiness.of(wiredWake(setting: .WAKE_SETTING_OFF)),
      WakeReadiness.wiredOff,
    );
    expect(
      WakeReadiness.of(wiredWake(setting: .WAKE_SETTING_UNSPECIFIED)),
      WakeReadiness.wiredUnknown,
    );
  });

  test('Wi-Fi alone is said honestly, even with the setting on', () {
    final wifi = WakeInfo(
      interfaces: [
        WakeInterface(
          mac: const [1, 2, 3, 4, 5, 6],
          broadcast: '192.168.1.255',
          link: .WAKE_LINK_WIFI,
          setting: .WAKE_SETTING_ON,
        ),
      ],
    );

    expect(WakeReadiness.of(wifi), WakeReadiness.wifiOnly);
  });

  test('nothing shared is unknown', () {
    expect(WakeReadiness.of(null), WakeReadiness.unknown);
    expect(WakeReadiness.of(WakeInfo()), WakeReadiness.unknown);
  });
}
