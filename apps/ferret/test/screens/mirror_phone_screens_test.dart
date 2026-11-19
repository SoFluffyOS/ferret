// Screen on the phone: Send sound too in its settings, "Sharing screen and
// sound with MacBook Air", a computer asking for control ("Let MacBook Air
// control Pixel 7 while showing its screen?"), "Being controlled by
// MacBook Air" with Stop control, and the Control from a computer
// settings with what Ferret control is, said before Android opens. Renders
// into temp/screens as `mirror_phone_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/mirror_phone_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:ferret_phone_control/testing.dart';
import 'package:ferret_power/testing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protocol/mirroring.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  MirroringFeatureUi mirroring,
);

/// A phone screen that says yes at once and sends nothing.
class _ScreenCapture implements ScreenCapture {
  final StreamController<CaptureEvent> _events = .broadcast();

  @override
  Stream<CaptureEvent> get events => _events.stream;

  @override
  Future<CaptureSupport> support() async =>
      const CaptureSupport(h264: true, jpeg: true);

  @override
  Future<AudioCaptureSupport> audioSupport() async => .ready;

  @override
  Future<bool> requestAudioPermission() async => true;

  @override
  Future<ConsentResult> requestConsent(
    ConsentTexts texts,
    Duration timeout,
  ) async => .granted;

  @override
  Future<void> cancelConsent() async {}

  @override
  Future<bool> start(CaptureOptions options) async => true;

  @override
  Future<void> stop() async {}

  @override
  Future<void> requestKeyframe() async {}

  @override
  Future<void> setBitrate(int bitrate) async {}

  @override
  Future<void> dispose() async => _events.close();
}

MirroringFeatureUi _phoneMirroring({required bool serviceOn}) =>
    MirroringFeatureUi(
      feature: MirroringFeature(
        capture: _ScreenCapture.new,
        phoneControl: () => PhoneControl(
          power: PowerCapabilities.withPlatform(FakePowerPlatform()),
          service: FakeControlService(enabled: serviceOn),
          supported: true,
        ),
        canShare: true,
        canView: false,
      ),
    );

/// The phone shows its screen to the paired MacBook Air.
Future<String> _shareWithComputer(
  WidgetTester tester,
  ScreenRig rig,
  MirroringFeatureUi mirroring, {
  bool withSound = false,
}) async {
  final computerId =
      await rig.pairConnectedComputer(
        tester,
        computerFeatures: [
          // A computer without the feature never answers, so the share
          // stays as the phone started it.
          for (final feature in appFeatures())
            if (feature.featureId != MirroringFeature.featureId) feature,
        ],
      ) ??
      '';
  await rig.settle(tester);
  await tester.runAsync(() async {
    final source = mirroring.feature.source;
    final session = rig.engine.sessionFor(computerId);
    if (source == null || session == null) {
      return;
    }

    if (withSound) {
      await source.setSendSound(true);
    }

    await source.onRequest(
      session,
      StartRequest(
        version: 1,
        codecs: const [.CODEC_H264],
        audioCodecs: [if (withSound) .AUDIO_CODEC_OPUS],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await rig.settle(tester);
  return computerId;
}

Future<void> _openSettings(
  WidgetTester tester,
  ScreenRig rig,
  MirroringFeatureUi mirroring,
) => rig.open(
  tester,
  Builder(
    builder: (context) => FerretPage(
      title: 'Screen',
      children: [
        mirroring.buildSettings(context, rig.featureContext) ??
            const SizedBox.shrink(),
      ],
    ),
  ),
);

const _serviceOn = {'sharing_sound', 'control_ask', 'controlled'};

final _screens = <String, _Script>{
  'sound_setting': (tester, rig, mirroring) async {
    await tester.runAsync(
      () async => mirroring.feature.source?.setSendSound(true),
    );
    await _openSettings(tester, rig, mirroring);
  },
  'sharing_sound': (tester, rig, mirroring) async {
    await _shareWithComputer(tester, rig, mirroring, withSound: true);
  },
  'control_ask': (tester, rig, mirroring) async {
    final computerId = await _shareWithComputer(tester, rig, mirroring);
    await tester.runAsync(
      () async => mirroring.feature.source?.control?.onAsk(computerId),
    );
    await rig.settle(tester);
  },
  'controlled': (tester, rig, mirroring) async {
    final computerId = await _shareWithComputer(tester, rig, mirroring);
    await tester.runAsync(() async {
      final control = mirroring.feature.source?.control;
      await control?.onAsk(computerId);
      await control?.answer(.once);
    });
    await rig.settle(tester);
  },
  'control_setting': (tester, rig, mirroring) async {
    await _openSettings(tester, rig, mirroring);
    await tester.scrollUntilVisible(
      find.text('Turn on Ferret control…'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
  },
  'control_disclosure': (tester, rig, mirroring) async {
    await _openSettings(tester, rig, mirroring);
    await tester.scrollUntilVisible(
      find.text('Turn on Ferret control…'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await rig.tapText(tester, 'Turn on Ferret control…');
  },
};

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('mirror phone $name ${brightness.name}', (tester) async {
        setScreen(tester, phone, brightness);
        mockPlugins(tester);
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = phone.platform;
        final reportError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('overflowed')) {
            return;
          }

          reportError?.call(details);
        };
        try {
          final mirroring = _phoneMirroring(
            serviceOn: _serviceOn.contains(name),
          );
          final features = [
            for (final feature in phoneFeatures())
              if (feature.featureId != MirroringFeature.featureId) feature,
            mirroring,
          ];
          final rig = await ScreenRig.create(
            tester,
            features: features,
            tipsDone: true,
            asPhone: true,
          );
          await rig.show(tester);
          await script(tester, rig, mirroring);
          await rig.capture(tester, 'mirror_phone_$name', phone, brightness);
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
