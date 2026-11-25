// Ferret on an iPad paired with a Mac: full screen both ways, an iPad Pro,
// Split View at a half, a third and two thirds, and Stage Manager windows,
// with the iPad's screen corner. Plus the Mac's view of a connected iPad.
// Renders into temp/screens as `ipad_<name>_<size>_<mode>.png`; overflows
// go to `temp/screens/ipad_overflows.txt`. Run from apps/ferret:
//
//   flutter test test/screens/ipad_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures;
import 'support/ios_features.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(WidgetTester tester, ScreenRig rig);

Future<void> _pairMac(WidgetTester tester, ScreenRig rig) async {
  await rig.pairConnectedComputer(tester, computerFeatures: appFeatures());
  await rig.settle(tester);
}

/// In the phone layout (a third, a small window) the device's sections
/// are on its own page: opens it first.
Future<void> _toDevice(WidgetTester tester, ScreenRig rig) async {
  await _pairMac(tester, rig);
  if (find.text('Overview').evaluate().isEmpty) {
    await rig.tapText(tester, 'MacBook Air');
  }
}

/// Settings is in the device list of the window layout, and a page of its
/// own in the phone layout.
Future<void> _toSettings(WidgetTester tester, ScreenRig rig) async {
  await _pairMac(tester, rig);
  if (find.text('Settings').evaluate().isEmpty) {
    await rig.open(tester, const SettingsPage());
    return;
  }

  await rig.tapText(tester, 'Settings');
}

/// The window's or Home's •••: the one nearest the top right.
Future<void> _openMenu(WidgetTester tester, ScreenRig rig) async {
  await _pairMac(tester, rig);
  final dots = find.byIcon(LucideIcons.ellipsis).evaluate().toList()
    ..sort((a, b) {
      final (pa, pb) = (
        (a.renderObject! as RenderBox).localToGlobal(Offset.zero),
        (b.renderObject! as RenderBox).localToGlobal(Offset.zero),
      );
      return (pa.dy - pa.dx).compareTo(pb.dy - pb.dx);
    });
  await tester.tap(find.byWidget(dots.first.widget).first);
  await rig.settle(tester);
}

final _screens = <String, _Script>{
  'empty': (tester, rig) async {},
  'home': _pairMac,
  'more': (tester, rig) async {
    await _toDevice(tester, rig);
    await rig.tapText(tester, 'More');
  },
  'files': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.tapText(tester, 'Files');
  },
  'activity': (tester, rig) async {
    await _pairMac(tester, rig);
    await rig.tapText(tester, 'Activity');
  },
  'settings': _toSettings,
  for (final group in ['Clipboard', 'Files', 'Continue & media', 'About'])
    'settings_${group.toLowerCase().replaceAll(RegExp('[^a-z]+'), '_')}':
        (tester, rig) async {
          await _toSettings(tester, rig);
          final count = find.text(group).evaluate().length;
          await rig.tapText(tester, group, index: count > 1 ? count - 1 : 0);
        },
  'add_device': (tester, rig) async {
    await _pairMac(tester, rig);
    await tester.tap(find.byIcon(LucideIcons.plus).first);
    await rig.settle(tester);
  },
  'menu': _openMenu,
  'device_menu': (tester, rig) async {
    await _pairMac(tester, rig);
    await tester.tap(
      find.text('MacBook Air').first,
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await rig.settle(tester);
  },
};

/// The screens rendered at every size; the rest only full screen and in
/// half.
const _everySize = {'home', 'settings', 'more', 'menu'};

/// Screens also captured at 200% text.
const _largeText = {'home', 'settings'};

final _overflows = <String>[];

Future<void> _render(
  WidgetTester tester,
  String label,
  Future<void> Function() body,
) async {
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
    await body();
  } finally {
    FlutterError.onError = reportError;
    debugDisableShadows = true;
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });
  tearDownAll(() async {
    await screensDirectory.create(recursive: true);
    await File(
      '${screensDirectory.path}/ipad_overflows.txt',
    ).writeAsString(switch ((_overflows.isEmpty, capturedOverflows.isEmpty)) {
      (true, true) => 'No overflows.\n',
      _ => '${{..._overflows, ...capturedOverflows}.join('\n')}\n',
    });
  });

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    final sizes = switch (_everySize.contains(name)) {
      true => ipadSizes,
      false => const [ipadLandscape, ipadHalf],
    };
    final runs = [
      for (final size in sizes)
        for (final brightness in Brightness.values)
          if (brightness == .light || size == ipadLandscape)
            (size, brightness, 1.0),
      if (_largeText.contains(name))
        for (final size in const [ipadLandscape, ipadThird])
          (size, Brightness.light, 2.0),
    ];
    for (final (size, brightness, scale) in runs) {
      final suffix = switch (scale) {
        1.0 => '',
        _ => '_text${(scale * 100).round()}',
      };
      final label = '$name$suffix ${size.name} ${brightness.name}';
      testWidgets('ipad $label', (tester) async {
        setScreen(tester, size, brightness);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        mockPlugins(tester);
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = size.platform;
        await _render(tester, label, () async {
          final rig = await ScreenRig.create(
            tester,
            features: iosFeatures(),
            tipsDone: true,
            asIpad: true,
          );
          await rig.show(tester);
          await script(tester, rig);
          await rig.capture(tester, 'ipad_$name$suffix', size, brightness);
          await rig.dispose(tester);
        });
      });
    }
  }

  // A Mac's window and popover with a connected iPad.
  for (final size in const [popover]) {
    testWidgets('ipad mac_ipad_device ${size.name}', (tester) async {
      setScreen(tester, size, .light);
      mockPlugins(tester);
      debugDisableShadows = false;
      debugDefaultTargetPlatformOverride = size.platform;
      await _render(tester, 'mac_ipad_device ${size.name}', () async {
        final rig = await ScreenRig.create(
          tester,
          features: appFeatures(),
          tipsDone: true,
        );
        await rig.show(tester);
        final id = await rig.pairConnectedIphone(
          tester,
          iphoneFeatures: iosFeatures(),
          name: 'iPad Air',
          formFactor: .FORM_FACTOR_TABLET,
        );
        if (id != null) {
          await rig.open(tester, DevicePage(deviceId: id));
        }
        await rig.capture(tester, 'ipad_mac_device', size, .light);
        await rig.dispose(tester);
      });
    });
  }
}
