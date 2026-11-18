// The window, rendered at one size per breakpoint, light and dark, into
// temp/screens as `window_<name>_<size>_<mode>.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/window_screens_test.dart
//
// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.
@Tags(['screens'])
library;

import 'dart:async';
import 'dart:io';

import 'package:calls/calls.dart';
import 'package:clipboard/clipboard.dart';
import 'package:drop/drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:find/find.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:iphone/iphone.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media/media.dart';
import 'package:messages/messages.dart';
import 'package:mirroring/mirroring.dart';
import 'package:notifications/notifications.dart';
import 'package:power/power.dart';
import 'package:remote_input/remote_input.dart';

import 'screens_test.dart' show phoneFeatures;
import 'support/sample_activity.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

/// The same list as `lib/main.dart`.
List<FeatureUi> appFeatures() => [
  CallsFeatureUi(),
  ClipboardFeatureUi(),
  DropFeatureUi(),
  FindFeatureUi(),
  HandoffFeatureUi(),
  IphoneFeatureUi(),
  MediaFeatureUi(),
  MessagesFeatureUi(),
  MirroringFeatureUi(),
  NotificationsFeatureUi(),
  PowerFeatureUi(),
  RemoteInputFeatureUi(),
];

/// One size inside each breakpoint from `normal` up; `small` is the phone
/// and the popover, which `screens_test.dart` covers.
const windowSizes = [
  CaptureSize('normal', 700, 800),
  CaptureSize('large', 1000, 720),
  CaptureSize('larger', 1280, 800),
  CaptureSize('extralarge', 1680, 1000),
];

typedef WindowScript = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
);

class WindowScreen {
  const WindowScreen(this.name, this.script, {this.sampleActivity = false});

  final String name;
  final WindowScript script;
  final bool sampleActivity;
}

Future<void> _nothing(WidgetTester tester, ScreenRig rig) async {}

Future<void> _pairPhone(WidgetTester tester, ScreenRig rig) async {
  await rig.pairConnectedPhone(tester, phoneFeatures: phoneFeatures());
  await rig.settle(tester);
}

final windowScreens = <WindowScreen>[
  const WindowScreen('empty', _nothing),
  WindowScreen('empty_nearby', (tester, rig) async {
    await rig.addNearby(tester, name: 'Pixel 9');
  }),
  const WindowScreen('overview', _pairPhone, sampleActivity: true),
  WindowScreen('overview_offline', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.settle(tester);
  }),
  WindowScreen('many_devices', (tester, rig) async {
    await _pairPhone(tester, rig);
    await rig.addOfflinePhone(tester, name: 'iPad');
    await rig.addOfflinePhone(tester, name: 'ThinkPad', id: 'b1b2c3d4e5f60718');
    await rig.addNearby(tester, name: 'Galaxy S24');
    await rig.settle(tester);
  }, sampleActivity: true),
  for (final section in [
    'Messages',
    'Notifications',
    'Files',
    'Screen',
  ])
    WindowScreen('section_${section.toLowerCase()}', (tester, rig) async {
      await _pairPhone(tester, rig);
      await rig.tapText(tester, section);
    }),
  WindowScreen('section_offline', (tester, rig) async {
    await _pairPhone(tester, rig);
    await rig.tapText(tester, 'Files');
    await rig.disconnectOthers(tester);
  }),
  WindowScreen('device_menu', (tester, rig) async {
    await _pairPhone(tester, rig);
    await tester.tap(find.text('Pixel 9').first, buttons: kSecondaryButton);
    await rig.settle(tester);
  }),
  WindowScreen('activity', (tester, rig) async {
    await _pairPhone(tester, rig);
    await rig.tapText(tester, 'Activity');
  }, sampleActivity: true),
  WindowScreen('activity_empty', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.settle(tester);
    await rig.tapText(tester, 'Activity');
  }),
  WindowScreen('settings', (tester, rig) async {
    await _pairPhone(tester, rig);
    await rig.tapText(tester, 'Settings');
  }),
  WindowScreen('add_device', (tester, rig) async {
    await _pairPhone(tester, rig);
    await rig.addNearby(tester, name: 'Galaxy S24');
    await tester.tap(find.byIcon(LucideIcons.plus));
    await rig.settle(tester);
  }),
  WindowScreen('fix_connection', (tester, rig) async {
    await rig.addOfflinePhone(tester);
    await rig.settle(tester);
    await rig.tapText(tester, "Why isn't it connecting?");
  }),
  WindowScreen('pair_request', (tester, rig) async {
    await _pairPhone(tester, rig);
    final other = await rig.startNearby(tester, name: 'Galaxy S24');
    if (other == null) {
      return;
    }

    await tester.runAsync(() async {
      unawaited(
        other.pairWithAddress(
          '127.0.0.1',
          rig.engine.port,
          onCode: (_) => true,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await rig.settle(tester);
  }),
  WindowScreen('sidebar_hidden', (tester, rig) async {
    await _pairPhone(tester, rig);
    await tester.tap(find.byIcon(LucideIcons.panelLeftClose));
    await rig.settle(tester);
  }),
];

final _overflows = <String>[];

void main() {
  setUpAll(loadScreenFonts);
  tearDownAll(() async {
    await screensDirectory.create(recursive: true);
    await File(
      '${screensDirectory.path}/window_overflows.txt',
    ).writeAsString(switch (_overflows.isEmpty) {
      true => 'No overflows.\n',
      false => '${_overflows.toSet().join('\n')}\n',
    });
  });

  for (final screen in windowScreens) {
    for (final size in windowSizes) {
      for (final brightness in Brightness.values) {
        final label = '${screen.name} ${size.name} ${brightness.name}';
        testWidgets('window $label', (tester) async {
          setScreen(tester, size, brightness);
          mockPlugins(tester);
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
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
              features: [
                ...appFeatures(),
                if (screen.sampleActivity) SampleActivityFeatureUi(),
              ],
              tipsDone: true,
            );
            await rig.show(tester);
            await screen.script(tester, rig);
            await rig.capture(
              tester,
              'window_${screen.name}',
              size,
              brightness,
            );
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
