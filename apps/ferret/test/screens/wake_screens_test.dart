// Wake-on-LAN: an offline Mac on a phone's Home with Wake, waking, didn't
// wake, its page while waking, and the help page. Renders into
// temp/screens as `wake_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/wake_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_wake/ferret_wake.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';
import 'package:wake/wake.dart';

import 'screens_test.dart' show phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  WakeFeatureUi wake,
);

/// Never puts a packet on the real network.
class _QuietSender implements WakeSender {
  @override
  Future<List<WakePacket>> send(List<WakePacket> packets) async => packets;
}

const _macId = 'c0ffee00c0ffee00';

final _macWake = WakeInfo(
  interfaces: [
    WakeInterface(
      mac: const [0x3c, 0x22, 0xfb, 0x12, 0x34, 0x56],
      address: '192.168.1.23',
      broadcast: '192.168.1.255',
      link: .WAKE_LINK_WIRED,
      setting: .WAKE_SETTING_ON,
    ),
    WakeInterface(
      mac: const [0x3c, 0x22, 0xfb, 0x12, 0x34, 0x57],
      address: '192.168.1.24',
      broadcast: '192.168.1.255',
      link: .WAKE_LINK_WIFI,
      setting: .WAKE_SETTING_ON,
    ),
  ],
);

Future<void> _addSleepingMac(WidgetTester tester, ScreenRig rig) async {
  await tester.runAsync(
    () => rig.engine.trustStore.save(
      TrustedDevice(
        id: _macId,
        name: 'MacBook Pro',
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_LAPTOP,
        publicKey: Uint8List(32),
        pairedAt: DateTime.now().subtract(const Duration(days: 20)),
        lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
        lastHost: '192.168.1.23',
        lastPort: 47640,
        wake: _macWake,
      ),
    ),
  );
  await rig.settle(tester);
}

Future<void> _wake(
  WidgetTester tester,
  ScreenRig rig,
  WakeFeatureUi wake,
) async {
  await tester.runAsync(() async {
    await wake.feature.wake(_macId);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await rig.settle(tester);
}

final _screens = <String, _Script>{
  'offline_row': (tester, rig, wake) => _addSleepingMac(tester, rig),
  'waking': (tester, rig, wake) async {
    await _addSleepingMac(tester, rig);
    await _wake(tester, rig, wake);
  },
  'waking_page': (tester, rig, wake) async {
    await _addSleepingMac(tester, rig);
    await _wake(tester, rig, wake);
    await rig.open(tester, const DevicePage(deviceId: _macId));
  },
  'didnt_wake': (tester, rig, wake) async {
    await _addSleepingMac(tester, rig);
    await _wake(tester, rig, wake);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await rig.settle(tester);
  },
  'help': (tester, rig, wake) async {
    await rig.open(
      tester,
      WakeHelpPage(
        platform: .PLATFORM_MACOS,
        deviceName: 'MacBook Pro',
        told: _macWake.interfaces,
        fromIphone: defaultTargetPlatform == .iOS,
      ),
    );
  },
};

/// The short wait only in "didn't wake", so the others stay "waking".
Duration _timeoutFor(String name) => switch (name) {
  'didnt_wake' => const Duration(milliseconds: 100),
  _ => const Duration(minutes: 5),
};

void main() {
  setUpAll(loadScreenFonts);

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final size in const [phone, iphone]) {
      for (final brightness in Brightness.values) {
        if (brightness == .dark && !size.darkToo) {
          continue;
        }

        testWidgets('wake $name ${size.name} ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, size, brightness);
          mockPlugins(tester);
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = size.platform;
          final reportError = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains('overflowed')) {
              return;
            }

            reportError?.call(details);
          };
          try {
            final wake = WakeFeatureUi(
              feature: WakeFeature(
                isComputer: false,
                sender: _QuietSender(),
                readCards: () async => const [],
                wakeTimeout: _timeoutFor(name),
              ),
            );
            final features = <FeatureUi>[...phoneFeatures(), wake];
            final rig = await ScreenRig.create(
              tester,
              features: features,
              tipsDone: true,
              asPhone: true,
            );
            await rig.show(tester);
            await script(tester, rig, wake);
            await rig.capture(tester, 'wake_$name', size, brightness);
            await rig.dispose(tester);
          } finally {
            FlutterError.onError = reportError;
            debugDisableShadows = true;
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
  }
}
