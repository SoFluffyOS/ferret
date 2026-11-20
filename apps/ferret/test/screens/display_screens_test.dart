// Another Mac as a display: "Use MacBook Air as a display" on a paired
// Mac's page, the Activity lines on the Mac that lends its desktop
// (asking, extending, Screen Recording missing, ended), and the question
// on the Mac that would become the display. The display window itself is
// in mirror_screens_test.dart (mirror_56 to mirror_59). Renders into
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

import 'screens_test.dart' show appFeatures;
import 'support/mirror_fakes.dart' show StillDisplay;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  List<FeatureUi> features,
);

const _window = CaptureSize('window', 1000, 720);

/// A Mac's features, with an extra display that never touches the system.
List<FeatureUi> _mac({bool screenRecording = true}) => [
  for (final feature in appFeatures())
    if (feature.featureId != MirroringFeature.featureId) feature,
  MirroringFeatureUi(
    feature: MirroringFeature(
      display: () => StillDisplay(screenRecording: screenRecording),
      canShare: false,
      canView: true,
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

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

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
