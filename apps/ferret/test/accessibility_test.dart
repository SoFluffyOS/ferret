// What must stay true for a screen reader, a keyboard and low vision, on
// the real app with a real engine. The wider audit, which only writes down
// what it finds, is `test/screens/a11y_audit_test.dart`.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens/screens_test.dart'
    show Screen, appFeatures, phoneFeatures, screens;
import 'screens/support/sample_activity.dart';
import 'screens/support/screen_harness.dart';

const _window = CaptureSize('window', 1000, 720);

/// The screens a first week with Ferret goes through.
const _mainScreens = {
  'home_empty',
  'home_connected',
  'home_nearby',
  'home_activity',
  'pair_code',
  'pair_request',
  'pair',
  'device_connected',
  'device_offline',
  'settings',
  'settings_group_general',
  'activity',
  'doctor',
  'phone_device_connected',
  'phone_settings',
};

Future<ScreenRig> _show(
  WidgetTester tester,
  Screen screen,
  CaptureSize size,
  Brightness brightness,
) async {
  setScreen(tester, size, brightness);
  mockPlugins(tester);
  final rig = await ScreenRig.create(
    tester,
    features: [
      ...switch (screen.phone) {
        true => phoneFeatures(),
        false => appFeatures(),
      },
      if (screen.sampleActivity) SampleActivityFeatureUi(),
    ],
    tipsDone: screen.tipsDone,
    asPhone: screen.phone,
  );
  await rig.show(tester);
  await screen.script(tester, rig);
  await rig.settle(tester);
  return rig;
}

/// Runs [body] on [platform] with layout overflows of the test font left
/// out: its glyphs are wider than any real font's.
Future<void> _on(TargetPlatform platform, Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = platform;
  final reportError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      return;
    }

    reportError?.call(details);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = reportError;
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  for (final screen in screens) {
    if (!_mainScreens.contains(screen.name)) {
      continue;
    }

    for (final brightness in Brightness.values) {
      final size = switch (screen.phone) {
        true => phone,
        false => popover,
      };
      testWidgets(
        '${screen.name} ${brightness.name}: everything tappable has a name, '
        'all text is readable',
        (tester) async {
          await _on(size.platform, () async {
            final semantics = tester.ensureSemantics();
            final rig = await _show(tester, screen, size, brightness);

            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));

            semantics.dispose();
            await rig.dispose(tester);
          });
        },
      );
    }
  }

  group('the window', () {
    final overview = Screen('window_overview', (tester, rig) async {
      await rig.pairConnectedPhone(tester, phoneFeatures: phoneFeatures());
      await rig.addOfflinePhone(tester, name: 'iPad');
      await rig.settle(tester);
    }, tipsDone: true);

    testWidgets('a screen reader finds the device list next to the page', (
      tester,
    ) async {
      await _on(.macOS, () async {
        final semantics = tester.ensureSemantics();
        final rig = await _show(tester, overview, _window, .light);

        expect(find.bySemanticsLabel('Add a device'), findsOneWidget);
        expect(find.bySemanticsLabel('Hide sidebar'), findsOneWidget);
        expect(
          tester.getSemantics(find.bySemanticsLabel('Settings')),
          isSemantics(
            label: 'Settings',
            isButton: true,
            hasSelectedState: true,
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('iPad')).tooltip,
          'Not connected',
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Pixel 9').first).tooltip,
          'Connected',
        );
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));

        semantics.dispose();
        await rig.dispose(tester);
      });
    });

    testWidgets('Tab leaves the page and walks the device list', (
      tester,
    ) async {
      await _on(.macOS, () async {
        final rig = await _show(tester, overview, _window, .light);
        final stops = <Rect>[];
        for (var press = 0; press < 60; press++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump(const Duration(milliseconds: 120));
          final rect = FocusManager.instance.primaryFocus?.rect;
          if (rect != null) {
            stops.add(rect);
          }
        }

        final inList = stops.where((rect) => rect.right <= 240);
        final inPage = stops.where((rect) => rect.left >= 240);
        expect(inPage, isNotEmpty, reason: 'Tab never reached the page');
        expect(inList, isNotEmpty, reason: 'Tab never reached the device list');

        await rig.dispose(tester);
      });
    });

    testWidgets('Tab leaves a page with nothing to press', (tester) async {
      final emptyActivity = Screen('window_activity_empty', (
        tester,
        rig,
      ) async {
        await rig.addOfflinePhone(tester);
        await rig.settle(tester);
        await rig.tapText(tester, 'Activity');
      }, tipsDone: true);

      await _on(.macOS, () async {
        final rig = await _show(tester, emptyActivity, _window, .light);
        final stops = <Rect>[];
        for (var press = 0; press < 12; press++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump(const Duration(milliseconds: 120));
          final rect = FocusManager.instance.primaryFocus?.rect;
          if (rect != null) {
            stops.add(rect);
          }
        }

        final inList = stops.where((rect) => rect.right <= 240);
        expect(inList, isNotEmpty, reason: 'Tab never left the empty page');
        expect(
          inList.toSet().length,
          greaterThan(1),
          reason: 'Tab stopped at one line of the device list',
        );

        await rig.dispose(tester);
      });
    });

    testWidgets('arrow keys walk the device list line by line', (
      tester,
    ) async {
      await _on(.macOS, () async {
        final rig = await _show(tester, overview, _window, .light);
        Rect? focused() => FocusManager.instance.primaryFocus?.rect;

        var presses = 0;
        while ((focused()?.right ?? 1000) > 240 && presses < 60) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump(const Duration(milliseconds: 120));
          presses++;
        }
        final first = focused();
        expect(first, isNotNull);

        final tops = <double>[first?.top ?? 0];
        for (var press = 0; press < 3; press++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump(const Duration(milliseconds: 120));
          tops.add(focused()?.top ?? 0);
        }

        expect((focused()?.right ?? 1000) <= 240, isTrue);
        expect(tops, orderedEquals([...tops]..sort()));
        expect(tops.toSet().length, 4, reason: 'each ↓ is one line down');

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump(const Duration(milliseconds: 120));
        expect(focused()?.top, tops[2]);

        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump(const Duration(milliseconds: 120));
        final last = focused();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump(const Duration(milliseconds: 120));
        expect(focused(), last, reason: 'the list ends at its last line');

        await rig.dispose(tester);
      });
    });
  });
}
