// Another of your devices wants to add or remove one here: the line under
// Needs you with Add / Not now or Remove / Keep. Renders into temp/screens
// as `group_<name>_*.png`. Run from apps/ferret:
//
//   flutter test test/screens/group_request_screens_test.dart
@Tags(['screens'])
library;

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

const _window = CaptureSize('window', 1000, 720);

void main() {
  setUpAll(loadScreenFonts);

  for (final removal in [false, true]) {
    final name = switch (removal) {
      true => 'remove',
      false => 'join',
    };
    for (final size in const [popover, _window, phone]) {
      for (final brightness in Brightness.values) {
        if (brightness == .dark && !size.darkToo) {
          continue;
        }

        testWidgets('group $name ${size.name} ${brightness.name}', (
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
            final asPhone = identical(size, phone);
            final rig = await ScreenRig.create(
              tester,
              features: appFeatures(),
              asPhone: asPhone,
              tipsDone: true,
            );
            await rig.show(tester);
            final askerId = switch (asPhone) {
              true => await rig.pairConnectedComputer(
                tester,
                computerFeatures: appFeatures(),
                name: 'MacBook Pro',
              ),
              false => await rig.pairConnectedPhone(
                tester,
                phoneFeatures: phoneFeatures(),
                name: 'Pixel 7',
              ),
            };
            await tester.runAsync(
              () => _ask(rig, askerId ?? '', removal: removal),
            );
            await rig.settle(tester);
            await rig.capture(tester, 'group_$name', size, brightness);
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

/// Has the paired device ask about Anna's iPad (an addition) or the
/// ThinkPad (a removal). The asker was paired a while ago, as in real use,
/// so its word waits for an answer.
Future<void> _ask(
  ScreenRig rig,
  String askerId, {
  required bool removal,
}) async {
  final engine = rig.engine;
  final asker = rig.others.last;
  final now = DateTime.now();
  final paired = engine.trustStore[askerId];
  if (paired == null) {
    return;
  }

  await engine.trustStore.save(
    TrustedDevice(
      id: paired.id,
      name: paired.ownName,
      platform: paired.platform,
      formFactor: paired.formFactor,
      publicKey: paired.publicKey,
      pairedAt: now.subtract(const Duration(days: 30)),
      lastSeen: paired.lastSeen,
      lastHost: paired.lastHost,
      lastPort: paired.lastPort,
    ),
  );

  final other = await DeviceIdentity.generate();
  final device = TrustedDevice(
    id: other.deviceId,
    name: switch (removal) {
      true => 'ThinkPad X1',
      false => "Anna's iPad",
    },
    platform: switch (removal) {
      true => .PLATFORM_LINUX,
      false => .PLATFORM_IOS,
    },
    formFactor: switch (removal) {
      true => .FORM_FACTOR_LAPTOP,
      false => .FORM_FACTOR_TABLET,
    },
    publicKey: other.publicKey,
    pairedAt: now.subtract(const Duration(days: 3)),
  );
  if (removal) {
    await engine.trustStore.save(device);
    await asker.trustStore.forget(
      .new(id: device.id, at: now, by: .everywhere),
    );
  } else {
    await asker.trustStore.save(device);
  }

  await asker.setSharesPairings(true);
  final deadline = now.add(const Duration(seconds: 5));
  while (engine.groupRequests.isEmpty && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}
