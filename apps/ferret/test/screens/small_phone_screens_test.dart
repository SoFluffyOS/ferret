// Ferret on an old, cheap Android phone paired with a Mac: a 720p screen
// (360×640 dp) and a narrow one (320 dp wide), at 130% text. Renders into
// temp/screens as `small_<name>_<size>_light.png`; overflows go to
// `temp/screens/small_overflows.txt`. Run from apps/ferret:
//
//   flutter test test/screens/small_phone_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:io';

import 'package:drop/drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(WidgetTester tester, ScreenRig rig);

const _small = CaptureSize(
  'small',
  360,
  640,
  platform: .android,
  darkToo: false,
  safeTop: 24,
);
const _narrow = CaptureSize(
  'narrow',
  320,
  640,
  platform: .android,
  darkToo: false,
  safeTop: 24,
);

Future<String?> _pairMac(WidgetTester tester, ScreenRig rig) async {
  final id = await rig.pairConnectedComputer(
    tester,
    computerFeatures: appFeatures(),
  );
  await rig.settle(tester);
  return id;
}

Future<void> _openGuest(WidgetTester tester, ScreenRig rig) async {
  await _pairMac(tester, rig);
  final drop = rig.app.features.whereType<DropFeatureUi>().single;
  final viewModel = drop.uiChanges as DropViewModel;
  await tester.runAsync(viewModel.receiveFromGuest);
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
  'home_menu': (tester, rig) async {
    await _pairMac(tester, rig);
    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await rig.settle(tester);
  },
  'device': (tester, rig) async {
    if (await _pairMac(tester, rig) case final id?) {
      await rig.open(tester, DevicePage(deviceId: id));
    }
  },
  'activity': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.open(tester, const ActivityPage());
  },
  'settings': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.open(tester, const SettingsPage());
  },
  for (final group in SettingsGroup.values)
    'settings_${group.name}': (tester, rig) async {
      await _pairMac(tester, rig);
      await rig.open(tester, SettingsGroupPage(group: group));
    },
  'add_device': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.open(tester, const PairPage());
  },
  'pair_qr': (tester, rig) async {
    await rig.open(tester, const QrPairPage());
  },
  'notifications_setup': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.openOffer(tester, 'notifications');
  },
  'messages_setup': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.openOffer(tester, 'messages');
  },
  'guest_open': _openGuest,
  'guest_unseen': (tester, rig) async {
    await _openGuest(tester, rig);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 31)),
    );
    await rig.settle(tester);
  },
};

final _overflows = <String>[];

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });
  tearDownAll(() async {
    await screensDirectory.create(recursive: true);
    await File(
      '${screensDirectory.path}/small_overflows.txt',
    ).writeAsString(switch ((_overflows.isEmpty, capturedOverflows.isEmpty)) {
      (true, true) => 'No overflows.\n',
      _ => '${{..._overflows, ...capturedOverflows}.join('\n')}\n',
    });
  });

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final size in const [_small, _narrow]) {
      final label = '${name}_text130 ${size.name}';
      testWidgets('small $label', (tester) async {
        setScreen(tester, size, .light);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
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
            name: 'Galaxy A12',
            tipsDone: true,
            asPhone: true,
          );
          await rig.show(tester);
          await script(tester, rig);
          await rig.capture(tester, 'small_${name}_text130', size, .light);
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
