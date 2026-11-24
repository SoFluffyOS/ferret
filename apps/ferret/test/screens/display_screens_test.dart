// Another Mac as a display: "Use MacBook Air as a display" on a paired
// Mac's page, the Activity lines on the Mac that lends its desktop
// (asking, extending, Screen Recording missing, ended), and the question
// on the Mac that would become the display. An Android phone or tablet as
// the display: "Use Pixel 9 as a display" on the Mac, and the question on
// the phone's Home (`display_phone_*`). The display itself is in
// mirror_screens_test.dart (mirror_56 to mirror_64). Renders into
// temp/screens as `display_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/display_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mirroring/mirroring.dart';
import 'package:shell/shell.dart' show DevicePage;

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/mirror_fakes.dart' show StillDisplay;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  List<FeatureUi> features,
);

const _window = CaptureSize('window', 1000, 720);
const _tablet = CaptureSize('tablet', 1194, 834, platform: .android);

/// A Mac's features, with an extra display that never touches the system.
/// Extending and being a display are set, not read from the computer the
/// test runs on, so Linux and Windows draw the same Mac.
List<FeatureUi> _mac({bool screenRecording = true}) => [
  for (final feature in appFeatures())
    if (feature.featureId != MirroringFeature.featureId) feature,
  MirroringFeatureUi(
    feature: MirroringFeature(
      display: () => StillDisplay(screenRecording: screenRecording),
      canShare: false,
      canView: true,
      canExtend: true,
      canBeDisplay: true,
    ),
  ),
];

/// An Android phone's features, with Screen able to be a Mac's display.
List<FeatureUi> _phone() => [
  for (final feature in phoneFeatures())
    if (feature.featureId != MirroringFeature.featureId) feature,
  MirroringFeatureUi(
    feature: MirroringFeature(
      canShare: false,
      canShareCamera: false,
      canView: false,
      canExtend: false,
      canBeDisplay: true,
      codecs: const [.h264, .jpeg],
    ),
  ),
];

MirroringFeature _mirroringOf(List<FeatureUi> features) =>
    features.whereType<MirroringFeatureUi>().single.feature;

Future<void> _until(bool Function() condition) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (condition()) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Pairs a MacBook Air that can be a display, and gives its features.
Future<(String, List<FeatureUi>)> _pairAir(
  WidgetTester tester,
  ScreenRig rig,
) async {
  final air = _mac();
  final airId =
      await rig.pairConnectedComputer(tester, computerFeatures: air) ?? '';
  await rig.settle(tester);
  return (airId, air);
}

/// Offers this Mac's display to the Air, and lets the Air say yes.
Future<void> _extend(
  WidgetTester tester,
  ScreenRig rig,
  List<FeatureUi> features,
) async {
  final (airId, air) = await _pairAir(tester, rig);
  final display = _mirroringOf(features).display;
  final routes = _mirroringOf(air).routes;
  await tester.runAsync(() async {
    await display?.offer(airId);
    await _until(() => routes?.requests.isNotEmpty ?? false);
    routes?.answer(routes.requests.single, allow: true);
    await _until(() => display?.current?.phase == .extending);
  });
  await rig.settle(tester);
}

final _screens = <String, (_Script, bool)>{
  'action': (
    (tester, rig, features) async {
      final (airId, _) = await _pairAir(tester, rig);
      await rig.open(tester, DevicePage(deviceId: airId));
      await rig.tapText(tester, 'More');
    },
    true,
  ),
  'asking': (
    (tester, rig, features) async {
      final (airId, _) = await _pairAir(tester, rig);
      await tester.runAsync(
        () async => _mirroringOf(features).display?.offer(airId),
      );
      await rig.settle(tester);
    },
    true,
  ),
  'extending': (_extend, true),
  'needs_screen_recording': (
    (tester, rig, features) async {
      final (airId, _) = await _pairAir(tester, rig);
      await tester.runAsync(
        () async => _mirroringOf(features).display?.offer(airId),
      );
      await rig.settle(tester);
    },
    false,
  ),
  'ended': (
    (tester, rig, features) async {
      await _extend(tester, rig, features);
      final display = _mirroringOf(features).display;
      await tester.runAsync(() async {
        await display?.stop();
        await _until(() => display?.lastRecord != null);
      });
      await rig.settle(tester);
    },
    true,
  ),
  'ask': (
    (tester, rig, features) async {
      final pro = _mac();
      await rig.pairConnectedComputer(
        tester,
        computerFeatures: pro,
        name: 'MacBook Pro',
      );
      await rig.settle(tester);
      final routes = _mirroringOf(features).routes;
      await tester.runAsync(() async {
        await _mirroringOf(
          pro,
        ).display?.offer(rig.engine.identity.deviceId);
        await _until(() => routes?.requests.isNotEmpty ?? false);
      });
      await rig.settle(tester);
    },
    true,
  ),
};

/// The phone's side: a MacBook Pro asks to use it as its display.
Future<void> _phoneAsked(
  WidgetTester tester,
  ScreenRig rig,
  List<FeatureUi> features,
) async {
  final pro = _mac();
  await rig.pairConnectedComputer(
    tester,
    computerFeatures: pro,
    name: 'MacBook Pro',
  );
  await rig.settle(tester);
  final routes = _mirroringOf(features).routes;
  await tester.runAsync(() async {
    await _mirroringOf(pro).display?.offer(rig.engine.identity.deviceId);
    await _until(() => routes?.requests.isNotEmpty ?? false);
  });
  await rig.settle(tester);
}

/// The Mac's side: "Use Pixel 9 as a display" on the phone's page.
Future<void> _phoneAction(
  WidgetTester tester,
  ScreenRig rig,
  List<FeatureUi> features,
) async {
  final pixelId =
      await rig.pairConnectedPhone(tester, phoneFeatures: _phone()) ?? '';
  await rig.settle(tester);
  await rig.open(tester, DevicePage(deviceId: pixelId));
  await rig.tapText(tester, 'More');
}

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  for (final size in const [phone, _tablet]) {
    for (final brightness in Brightness.values) {
      testWidgets('display phone_ask ${size.name} ${brightness.name}', (
        tester,
      ) async {
        setScreen(tester, size, brightness);
        mockPlugins(tester);
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = size.platform;
        final reportError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('overflowed')) {
            debugPrint('screens: overflow in phone_ask ${size.name}');
            return;
          }

          reportError?.call(details);
        };
        try {
          final features = _phone();
          final rig = await ScreenRig.create(
            tester,
            features: features,
            tipsDone: true,
            asPhone: true,
          );
          await rig.show(tester);
          await _phoneAsked(tester, rig, features);
          await rig.capture(tester, 'display_phone_ask', size, brightness);
          await rig.dispose(tester);
        } finally {
          FlutterError.onError = reportError;
          debugDisableShadows = true;
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }

  for (final size in const [popover, _window]) {
    for (final brightness in Brightness.values) {
      testWidgets('display phone_action ${size.name} ${brightness.name}', (
        tester,
      ) async {
        setScreen(tester, size, brightness);
        mockPlugins(tester);
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = size.platform;
        try {
          final features = _mac();
          final rig = await ScreenRig.create(
            tester,
            features: features,
            tipsDone: true,
          );
          await rig.show(tester);
          await _phoneAction(tester, rig, features);
          await rig.capture(tester, 'display_phone_action', size, brightness);
          await rig.dispose(tester);
        } finally {
          debugDisableShadows = true;
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }

  for (final MapEntry(key: name, value: (script, screenRecording))
      in _screens.entries) {
    for (final size in const [popover, _window]) {
      for (final brightness in Brightness.values) {
        testWidgets('display $name ${size.name} ${brightness.name}', (
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
            final features = _mac(screenRecording: screenRecording);
            final rig = await ScreenRig.create(
              tester,
              features: features,
              tipsDone: true,
            );
            await rig.show(tester);
            await script(tester, rig, features);
            await rig.capture(tester, 'display_$name', size, brightness);
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
