// Persona #8, back after four months: Ferret was updated, the phone was
// replaced by a new Pixel 7 with the same name, and another phone runs a
// newer Ferret than this Mac. Renders into temp/screens as
// `returning_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/returning_screens_test.dart
@Tags(['screens'])
library;

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

const _oldPixelId = '99aa88bb77cc3f2a';

/// The Pixel 7 from before the reset: paired ten months ago, gone for four.
Future<void> _addOldPixel(WidgetTester tester, ScreenRig rig) async {
  await tester.runAsync(() async {
    final now = DateTime.now();
    await rig.engine.trustStore.save(
      TrustedDevice(
        id: _oldPixelId,
        name: 'Pixel 7',
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
        publicKey: Uint8List(32),
        pairedAt: now.subtract(const Duration(days: 300)),
        lastSeen: now.subtract(const Duration(days: 122)),
      ),
    );
  });
}

/// Pairs a Galaxy whose Ferret no longer speaks this Mac's protocol.
Future<String?> _pairNewerGalaxy(
  WidgetTester tester,
  ScreenRig rig,
  List<FerretEngine> others,
) => tester.runAsync<String?>(() async {
  final galaxy = await FerretEngine.create(
    secrets: MemorySecretStore(),
    settings: MemorySettingsStore(),
    device: const LocalDevice(
      name: 'Galaxy S24',
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      appVersion: '0.3.0',
      newestProtocol: 2,
      oldestProtocol: 2,
    ),
    discovery: SilentDiscovery(),
    port: 0,
  );
  await galaxy.start();
  others.add(galaxy);

  final handle = await rig.engine.createPairingOffer();
  final offer = PairingCodes.parseOffer(handle.qrText);
  if (offer == null) {
    return null;
  }

  offer
    ..hosts.clear()
    ..hosts.add('127.0.0.1');
  await galaxy.pairWithOffer(offer);
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (rig.engine.devices.every((status) => status.versionMismatch == null) &&
      DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  return galaxy.identity.deviceId;
});

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  List<FerretEngine> others,
);

final _screens = <String, _Script>{
  'home': (tester, rig, others) async {
    await rig.pairConnectedPhone(
      tester,
      phoneFeatures: phoneFeatures(),
      name: 'Pixel 7',
    );
    await _addOldPixel(tester, rig);
    await _pairNewerGalaxy(tester, rig, others);
    await rig.settle(tester);
  },
  'new_pixel': (tester, rig, others) async {
    final pixelId = await rig.pairConnectedPhone(
      tester,
      phoneFeatures: phoneFeatures(),
      name: 'Pixel 7',
    );
    await _addOldPixel(tester, rig);
    await rig.open(tester, DevicePage(deviceId: pixelId ?? ''));
  },
  'update_here': (tester, rig, others) async {
    final galaxyId = await _pairNewerGalaxy(tester, rig, others);
    await rig.open(tester, DevicePage(deviceId: galaxyId ?? ''));
  },
};

void main() {
  setUpAll(loadScreenFonts);

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final size in const [popover, phone]) {
      for (final brightness in Brightness.values) {
        if (brightness == .dark && !size.darkToo) {
          continue;
        }

        testWidgets('returning $name ${size.name} ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, size, brightness);
          mockPlugins(tester);
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = size.platform;
          final others = <FerretEngine>[];
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
              name: 'MacBook Pro',
              tipsDone: true,
            );
            await tester.runAsync(
              () => rig.engine.settings.set(WhatsNew.seenVersionKey, '0.0.9'),
            );
            await rig.show(tester);
            await script(tester, rig, others);
            await rig.capture(tester, 'returning_$name', size, brightness);
            await tester.runAsync(() async {
              for (final engine in others) {
                await engine.stop();
              }
            });
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
