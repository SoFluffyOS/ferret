// A Windows 11 laptop's view: the window at the sizes a 1080p screen at
// 150% gives (maximized, snapped to half, snapped to a third), light and
// dark, Fix connection's Windows lines, and Contrast themes on. Into
// temp/screens as `win_<name>_<size>_<mode>.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/windows_screens_test.dart
@Tags(['screens'])
library;

import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'support/sample_activity.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';
import 'window_screens_test.dart' show WindowScreen, appFeatures, windowScreens;

/// 1920 × 1080 at 150% is 1280 × 720; the taskbar takes 48.
const _maximized = CaptureSize('max150', 1280, 672);
const _half = CaptureSize('half150', 640, 672);
const _third = CaptureSize('third150', 426, 672);

const _named = {'overview', 'settings', 'device_menu', 'activity'};

/// Fix connection for an offline phone, with [rules] answering as Windows
/// would.
WindowScreen _doctor(String name, WindowsFirewallRules rules) =>
    WindowScreen(name, (tester, rig) async {
      await rig.addPhoneLastSeenAt(tester, host: '192.168.1.20');
      await rig.open(
        tester,
        DoctorPage(
          deviceId: 'a1b2c3d4e5f60718',
          doctorFor: (engine) => ConnectionDoctor(
            engine,
            isWindows: true,
            isLinux: false,
            program: r'C:\Users\An\AppData\Local\Programs\Ferret\ferret.exe',
            windowsFirewallRules: rules,
            interfaces: () async => [(name: 'Wi-Fi', address: '192.168.1.5')],
            probe: (host, port, timeout) async => Reach.silent,
            route: (host) async => 'Wi-Fi',
          ),
        ),
      );
      await rig.settle(tester, real: const Duration(seconds: 1));
    });

WindowsFirewallRules _rules({String categories = '', int blocks = 0}) =>
    WindowsFirewallRules(
      run: (executable, arguments) async {
        if (arguments.contains('-Command')) {
          return ProcessResult(
            0,
            0,
            switch (arguments.last.contains('Get-NetConnectionProfile')) {
              true => categories,
              false => '$blocks\n',
            },
            '',
          );
        }
        return ProcessResult(0, 0, '', '');
      },
    );

final _screens = [
  ...windowScreens.where((screen) => _named.contains(screen.name)),
  _doctor('doctor_public', _rules(categories: 'Wi-Fi|Public\n')),
  _doctor('doctor_blocked', _rules(blocks: 2)),
];

Future<void> _render(
  WidgetTester tester,
  WindowScreen screen,
  CaptureSize size,
  Brightness brightness, {
  String suffix = '',
}) async {
  setScreen(tester, size, brightness);
  mockPlugins(tester);
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  try {
    final rig = await ScreenRig.create(
      tester,
      name: 'Surface Laptop',
      features: [
        ...appFeatures(),
        if (screen.sampleActivity) SampleActivityFeatureUi(),
      ],
      tipsDone: true,
    );
    await rig.show(tester);
    await screen.script(tester, rig);
    await rig.capture(tester, 'win_${screen.name}$suffix', size, brightness);
    await rig.dispose(tester);
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  setUpAll(loadScreenFonts);

  for (final screen in _screens) {
    for (final size in [_maximized, _half, _third]) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'windows ${screen.name} ${size.name} ${brightness.name}',
          (
            tester,
          ) => _render(tester, screen, size, brightness),
        );
      }
    }
  }

  // Contrast themes (Settings → Accessibility): Windows tells apps, and
  // Ferret should still read.
  for (final screen in _screens.take(2)) {
    testWidgets('windows ${screen.name} high contrast', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _render(tester, screen, _maximized, .dark, suffix: '_contrast');
    });
  }
}
