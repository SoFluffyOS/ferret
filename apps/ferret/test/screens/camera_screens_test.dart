// Camera: Take a photo on a phone's page on the Mac, the Activity lines
// while waiting and after ("Photo from Pixel 7 · On your clipboard"), and
// the request card on the phone ("MacBook Air wants a photo"). Renders into
// temp/screens as `camera_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/camera_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_camera/ferret_camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:phone_camera/phone_camera.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  List<FeatureUi> features,
);

const _window = CaptureSize('window', 1000, 720);

/// Screens that run as a phone paired with a Mac.
const _phoneScreens = {'phone_ask'};

/// A phone camera that never opens: the renders stop at the request.
class _ScreenCamera implements PhoneCamera {
  const _ScreenCamera();

  @override
  bool get isSupported => true;

  @override
  bool get scansDocuments => false;

  @override
  Future<CameraAbilities> abilities() async =>
      const CameraAbilities(photo: true, document: false);

  @override
  Future<CameraCapture> takePhoto() => Completer<CameraCapture>().future;

  @override
  Future<CameraCapture> scanDocument() async =>
      const CameraCapture(.unavailable);
}

CameraFeatureUi _phoneCamera() =>
    CameraFeatureUi(feature: CameraFeature(camera: const _ScreenCamera()));

CameraFeatureUi _computerCamera() => CameraFeatureUi(
  feature: CameraFeature(camera: const UnsupportedPhoneCamera()),
);

CameraFeature _cameraOf(List<FeatureUi> features) =>
    features.whereType<CameraFeatureUi>().single.feature;

Future<String> _pairPixel(WidgetTester tester, ScreenRig rig) async {
  final phoneId =
      await rig.pairConnectedPhone(
        tester,
        phoneFeatures: [...phoneFeatures(), _phoneCamera()],
        name: 'Pixel 7',
      ) ??
      '';
  await rig.settle(tester);
  return phoneId;
}

final _screens = <String, _Script>{
  'action': (tester, rig, features) async {
    await _pairPixel(tester, rig);
    await rig.tapText(tester, 'More');
  },
  'waiting': (tester, rig, features) async {
    final phoneId = await _pairPixel(tester, rig);
    await tester.runAsync(() => _cameraOf(features).request(phoneId));
    await rig.settle(tester);
  },
  'activity': (tester, rig, features) async {
    final phoneId = await _pairPixel(tester, rig);
    final now = DateTime.now();
    _cameraOf(features).jobs
      ..add(
        CaptureJob(
          id: 'declined',
          deviceId: phoneId,
          kind: .photo,
          startedAt: now.subtract(const Duration(minutes: 9)),
          status: .declined,
        ),
      )
      ..add(
        CaptureJob(
          id: 'permission',
          deviceId: phoneId,
          kind: .photo,
          startedAt: now.subtract(const Duration(minutes: 5)),
          status: .noPermission,
        ),
      )
      ..add(
        CaptureJob(
          id: 'done',
          deviceId: phoneId,
          kind: .photo,
          startedAt: now,
          status: .done,
          fraction: 1,
          paths: const ['/Users/me/Downloads/Photo 2026-11-19 at 14.03.07.jpg'],
          mimeType: 'image/jpeg',
          onClipboard: true,
        ),
      );
    await rig.settle(tester);
  },
  'phone_ask': (tester, rig, features) async {
    final computer = _computerCamera();
    await rig.pairConnectedComputer(
      tester,
      computerFeatures: [...appFeatures(), computer],
    );
    await rig.settle(tester);
    await tester.runAsync(
      () => computer.feature.request(rig.engine.identity.deviceId),
    );
    await rig.settle(tester);
  },
};

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    final asPhone = _phoneScreens.contains(name);
    for (final size in const [popover, _window, phone]) {
      if (asPhone != (size == phone)) {
        continue;
      }

      for (final brightness in Brightness.values) {
        testWidgets('camera $name ${size.name} ${brightness.name}', (
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
            final features = switch (asPhone) {
              true => [...phoneFeatures(), _phoneCamera()],
              false => [...appFeatures(), _computerCamera()],
            };
            final rig = await ScreenRig.create(
              tester,
              features: features,
              tipsDone: true,
              asPhone: asPhone,
            );
            await rig.show(tester);
            await script(tester, rig, features);
            await rig.capture(tester, 'camera_$name', size, brightness);
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
