// The quick wins from temp/research/feature_gaps.md: Recent clips, battery
// on device rows, Lock this computer and the presentation remote. Renders
// into temp/screens as `quick_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/quick_wins_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'package:clipboard/clipboard.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/clipboard.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  List<FeatureUi> features,
);

final _screens = <String, _Script>{
  'recent_clips': (tester, rig, features) async {
    final phoneId =
        await rig.pairConnectedPhone(
          tester,
          phoneFeatures: phoneFeatures(),
          name: 'Pixel 7',
        ) ??
        '';
    final clipboard = features.whereType<ClipboardFeatureUi>().single;
    final session = rig.engine.sessionFor(phoneId);
    await tester.runAsync(() async {
      if (session == null) {
        return;
      }

      for (final (index, text) in const [
        'Meet at the north entrance, 7:30',
        'https://example.org/tickets/4471',
        'Ferret keeps the last 20 clips in memory only',
      ].indexed) {
        await clipboard.feature.onEnvelope(
          session,
          _clip(index, text, phoneId),
        );
      }
      await clipboard.feature.onEnvelope(
        session,
        _clip(9, 'hunter2', phoneId, sensitive: true),
      );
    });
    final home = tester.element(find.byType(HomePage));
    clipboard.appActions(home, rig.featureContext).single.onPressed?.call();
    await rig.settle(tester);
  },
};

Envelope _clip(int index, String text, String from, {bool sensitive = false}) {
  final push = ClipPush(
    item: ClipItem(
      id: 'clip-$index',
      kind: switch (text.startsWith('https://')) {
        true => .CLIP_KIND_URL,
        false => .CLIP_KIND_TEXT,
      },
      text: text,
      sourceDeviceId: from,
      sensitive: sensitive,
      createdAtMs: Int64(DateTime.now().millisecondsSinceEpoch),
    ),
    expiresInMs: Int64(120000),
  );

  return Envelope(
    id: Int64(index + 1),
    feature: ClipboardFeature.featureId,
    type: push.payloadType,
    payload: push.toPayload(),
  );
}

void main() {
  setUpAll(loadScreenFonts);

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final size in const [popover, phone]) {
      for (final brightness in Brightness.values) {
        if (brightness == .dark && !size.darkToo) {
          continue;
        }

        testWidgets('quick $name ${size.name} ${brightness.name}', (
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
            final features = appFeatures();
            final rig = await ScreenRig.create(
              tester,
              features: features,
              name: 'MacBook Air',
              tipsDone: true,
            );
            await rig.show(tester);
            await script(tester, rig, features);
            await rig.capture(tester, 'quick_$name', size, brightness);
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
