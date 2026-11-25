// Reaching a phone over your own VPN. Renders into temp/screens as
// `vpn_<name>_<size>_<mode>.png`. Run from apps/ferret:
//
//   flutter test test/screens/vpn_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  String phoneId,
);

const _window = CaptureSize('window', 1000, 720);

/// Turns reaching on and, once the test phone has answered with none, stores
/// the addresses a phone on a tailnet would have shared.
Future<void> _reach(WidgetTester tester, ScreenRig rig, String phoneId) async {
  await tester.runAsync(() async {
    await rig.engine.setReachOverVpn(phoneId, reach: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final trusted = rig.engine.trustStore[phoneId];
    if (trusted != null) {
      await rig.engine.trustStore.save(
        trusted.copyWith(
          vpnAddresses: const ['100.101.102.103', 'fd7a:115c:a1e0::1'],
        ),
      );
    }
  });
  await rig.settle(tester);
}

final _screens = <String, _Script>{
  'off': (tester, rig, phoneId) async {},
  'on': _reach,
  'reach_at': (tester, rig, phoneId) async {
    await _reach(tester, rig, phoneId);
    await tester.runAsync(
      () => rig.engine.setReachAt(phoneId, 'pixel-7.tail1234.ts.net'),
    );
    await rig.settle(tester);
  },
};

void main() {
  setUpAll(loadScreenFonts);
  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final size in [popover, _window]) {
      for (final brightness in Brightness.values) {
        testWidgets('vpn $name ${size.name} ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, size, brightness);
          mockPlugins(tester);
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          final reportError = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains('overflowed')) {
              return;
            }
            reportError?.call(details);
          };
          try {
            final rig = await ScreenRig.create(
              tester,
              features: appFeatures(),
              tipsDone: true,
            );
            await rig.show(tester);
            final phoneId =
                await rig.pairConnectedPhone(
                  tester,
                  phoneFeatures: phoneFeatures(),
                  name: 'Pixel 7',
                ) ??
                '';
            await script(tester, rig, phoneId);
            await rig.open(tester, DeviceVpnPage(deviceId: phoneId));
            await rig.capture(tester, 'vpn_$name', size, brightness);
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
