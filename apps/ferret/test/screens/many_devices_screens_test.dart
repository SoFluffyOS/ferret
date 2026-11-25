// Persona #7, someone with seven paired devices: Home, drop tiles, a
// device that shares its name, Activity from several phones, and the
// window's device list. Renders into temp/screens as `many_<name>_*.png`.
// Run from apps/ferret:
//
//   flutter test test/screens/many_devices_screens_test.dart
@Tags(['screens'])
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/device_family.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef FamilyScript = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
);

class FamilyScreen {
  const FamilyScreen(this.name, this.script, {this.window = false});

  final String name;
  final FamilyScript script;

  /// Rendered as a Mac window instead of the popover and phone.
  final bool window;
}

const _windowSize = CaptureSize('large', 1000, 720);

Future<void> _family(WidgetTester tester, ScreenRig rig) async {
  await pairFamily(tester, rig, phoneFeatures: phoneFeatures);
}

final familyScreens = <FamilyScreen>[
  const FamilyScreen('home', _family),
  FamilyScreen('home_all', (tester, rig) async {
    await _family(tester, rig);
    await rig.tapText(tester, 'Show');
  }),
  FamilyScreen('drop', (tester, rig) async {
    await _family(tester, rig);
    tester
        .element(find.byType(HomePage))
        .read<OsDropViewModel>()
        .enter(
          const Offset(20, 20),
          fileCount: 3,
        );
    await rig.settle(tester);
  }),
  FamilyScreen('namesake', (tester, rig) async {
    await _family(tester, rig);
    await rig.open(tester, const DevicePage(deviceId: oldPixelId));
  }),
  FamilyScreen('activity', (tester, rig) async {
    await _family(tester, rig);
    await rig.open(tester, const ActivityPage());
  }),
  FamilyScreen('pinned', (tester, rig) async {
    await _family(tester, rig);
    await tester.runAsync(
      () => DevicePreferences(
        rig.engine.settings,
      ).setPinned(thinkpadId, pinned: true),
    );
    await rig.tapText(tester, 'Show');
  }),
  FamilyScreen('stale_confirm', (tester, rig) async {
    await _family(tester, rig);
    await rig.tapText(tester, 'Show');
    await rig.tapText(tester, 'Remove…');
  }),
  FamilyScreen('rename', (tester, rig) async {
    await _family(tester, rig);
    await rig.open(tester, const DevicePage(deviceId: oldPixelId));
    await rig.tapText(tester, 'Rename…');
  }),
  FamilyScreen('renamed', (tester, rig) async {
    await _family(tester, rig);
    await tester.runAsync(
      () => rig.engine.renameDevice(oldPixelId, 'Old Pixel (drawer)'),
    );
    await rig.tapText(tester, 'Show');
  }),
  FamilyScreen('activity_filtered', (tester, rig) async {
    await _family(tester, rig);
    await rig.open(tester, const ActivityPage());
    await rig.tapText(tester, 'iPhone');
  }),
  const FamilyScreen('window', _family, window: true),
  FamilyScreen('window_pinned', (tester, rig) async {
    await _family(tester, rig);
    await tester.runAsync(
      () => DevicePreferences(
        rig.engine.settings,
      ).setPinned(thinkpadId, pinned: true),
    );
    await rig.settle(tester);
  }, window: true),
  FamilyScreen('window_search', (tester, rig) async {
    await _family(tester, rig);
    await addMoreFamily(tester, rig);
    await tester.enterText(find.byType(EditableText).first, 'pix');
    await rig.settle(tester);
  }, window: true),
  FamilyScreen('window_menu', (tester, rig) async {
    await _family(tester, rig);
    await tester.tap(find.text('ThinkPad X1').first, buttons: kSecondaryButton);
    await rig.settle(tester);
  }, window: true),
  FamilyScreen('window_activity', (tester, rig) async {
    await _family(tester, rig);
    await rig.tapText(tester, 'Activity');
  }, window: true),
];

void main() {
  setUpAll(loadScreenFonts);
  tearDownAll(() async {
    await screensDirectory.create(recursive: true);
    await File('${screensDirectory.path}/many_overflows.txt').writeAsString(
      switch (capturedOverflows.isEmpty) {
        true => 'No overflows.\n',
        false => '${capturedOverflows.toSet().join('\n')}\n',
      },
    );
  });

  for (final screen in familyScreens) {
    final screenSizes = switch (screen.window) {
      true => const [_windowSize],
      false => const [popover, phone],
    };
    for (final size in screenSizes) {
      for (final brightness in Brightness.values) {
        if (brightness == .dark && !size.darkToo) {
          continue;
        }

        testWidgets('many ${screen.name} ${size.name} ${brightness.name}', (
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
            final rig = await ScreenRig.create(
              tester,
              features: [...appFeatures(), FamilyActivityFeatureUi()],
              name: 'MacBook Pro',
              tipsDone: true,
            );
            await rig.show(tester);
            await screen.script(tester, rig);
            await rig.capture(tester, 'many_${screen.name}', size, brightness);
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
