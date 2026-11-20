// Ferret on an Android tablet paired with a Mac: held both ways, and beside
// another app in split screen, at 100% and at large text. Renders into
// temp/screens as `tablet_<name>_<size>_<mode>.png`; overflows go to
// `temp/screens/tablet_overflows.txt`. Run from apps/ferret:
//
//   fvm flutter test test/screens/tablet_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(WidgetTester tester, ScreenRig rig);

Future<void> _pairMac(WidgetTester tester, ScreenRig rig) async {
  await rig.pairConnectedComputer(tester, computerFeatures: appFeatures());
  await rig.settle(tester);
}

final _screens = <String, _Script>{
  'empty': (tester, rig) async {},
  'nearby': (tester, rig) async {
    await rig.addNearby(
      tester,
      name: 'MacBook Air',
      platform: .PLATFORM_MACOS,
      formFactor: .FORM_FACTOR_LAPTOP,
    );
  },
  'home': _pairMac,
  'more': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.tapText(tester, 'More');
  },
  'files': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.tapText(tester, 'Files');
  },
  'screen': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.tapText(tester, 'Screen');
  },
  'activity': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.tapText(tester, 'Activity');
  },
  'settings': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.tapText(tester, 'Settings');
  },
  for (final group in [
    'Clipboard',
    'Files',
    'Continue & media',
    'To your computer',
    'Control',
    'Other apps',
  ])
    'settings_${group.toLowerCase().replaceAll(RegExp('[^a-z]+'), '_')}':
        (tester, rig) async {
          await _pairMac(tester, rig);
          await rig.tapText(tester, 'Settings');
          await rig.tapText(tester, group, index: group == 'Files' ? 1 : 0);
        },
  'add_device': (tester, rig) async {
    await _pairMac(tester, rig);
    await tester.tap(find.byIcon(LucideIcons.plus).first);
    await rig.settle(tester);
  },
  'notifications_setup': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.openOffer(tester, 'notifications');
  },
  'messages_setup': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.openOffer(tester, 'messages');
  },
};

/// Screens also captured at 130% and 200% text, landscape and half.
const _largeText = {'home', 'settings', 'activity', 'more'};

final _overflows = <String>[];

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });
  tearDownAll(() async {
    await screensDirectory.create(recursive: true);
    await File(
      '${screensDirectory.path}/tablet_overflows.txt',
    ).writeAsString(switch ((_overflows.isEmpty, capturedOverflows.isEmpty)) {
      (true, true) => 'No overflows.\n',
      _ => '${{..._overflows, ...capturedOverflows}.join('\n')}\n',
    });
  });

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    final runs = [
      for (final size in tabletSizes)
        for (final brightness in Brightness.values) (size, brightness, 1.0),
      if (_largeText.contains(name))
        for (final size in const [tabletLandscape, tabletHalf])
          for (final scale in const [1.3, 2.0]) (size, Brightness.light, scale),
    ];
    for (final (size, brightness, scale) in runs) {
      final suffix = switch (scale) {
        1.0 => '',
        _ => '_text${(scale * 100).round()}',
      };
      final label = '$name$suffix ${size.name} ${brightness.name}';
      testWidgets('tablet $label', (tester) async {
        setScreen(tester, size, brightness);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        mockPlugins(tester);
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = size.platform;
        final reportError = FlutterError.onError;
        FlutterError.onError = (details) {
          final message = details.exceptionAsString();
          if (message.contains('overflowed')) {
            _overflows.add('$label: ${message.split('\n').first}');
            return;
          }

          reportError?.call(details);
        };
        try {
          final rig = await ScreenRig.create(
            tester,
            features: phoneFeatures(),
            name: 'Galaxy Tab S9',
            tipsDone: true,
            asTablet: true,
          );
          await rig.show(tester);
          await script(tester, rig);
          await rig.capture(tester, 'tablet_$name$suffix', size, brightness);
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
