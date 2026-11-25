// Persona #34, a new computer: Migration Assistant (or a restored backup)
// brought Ferret's data along, so Ferret starts over as a new device here
// and lists what to pair again. Renders into temp/screens as
// `moved_home*_*.png`. Run from apps/ferret:
//
//   flutter test test/screens/moved_screens_test.dart
@Tags(['screens'])
library;

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

const _window = CaptureSize('window', 1000, 720);

final _moved = MovedFrom(
  at: DateTime.utc(2026, 11, 22),
  devices: const [
    MovedDevice(
      id: 'aaaabbbbccccdddd',
      name: 'Pixel 7',
      platform: .PLATFORM_ANDROID,
    ),
    MovedDevice(
      id: 'eeeeffffgggghhhh',
      name: 'iPad Air',
      platform: .PLATFORM_IOS,
    ),
    MovedDevice(
      id: 'iiiijjjjkkkkllll',
      name: 'Work PC',
      platform: .PLATFORM_WINDOWS,
    ),
  ],
);

void main() {
  setUpAll(loadScreenFonts);

  final runs = [
    for (final size in [popover, _window, phone])
      for (final brightness in Brightness.values) (size, brightness, 1.0),
    (popover, Brightness.light, 1.3),
    (_window, Brightness.light, 1.3),
    (phone, Brightness.light, 1.3),
  ];

  for (final (size, brightness, scale) in runs) {
    final suffix = switch (scale) {
      1.0 => '',
      _ => '_text${(scale * 100).round()}',
    };
    testWidgets('moved home$suffix ${size.name} ${brightness.name}', (
      tester,
    ) async {
      setScreen(tester, size, brightness);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      mockPlugins(tester);
      debugDisableShadows = false;
      debugDefaultTargetPlatformOverride = size.platform;
      try {
        final rig = await ScreenRig.create(
          tester,
          features: switch (size == phone) {
            true => phoneFeatures(),
            false => appFeatures(),
          },
          name: 'MacBook Pro',
          tipsDone: true,
          asPhone: size == phone,
        );
        await tester.runAsync(
          () => rig.engine.settings.set(
            IdentityHome.movedKey,
            _moved.toJson(),
          ),
        );
        await rig.show(tester);
        await rig.settle(tester);
        expect(find.textContaining('Pixel 7, iPad Air, Work PC'), findsOne);
        await rig.capture(tester, 'moved_home$suffix', size, brightness);
        await rig.dispose(tester);
      } finally {
        debugDisableShadows = true;
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
