// Persona #10, a family sharing one computer: Anna and Ben each have an
// account on the Mac, both run Ferret, and Anna's phone is paired with
// hers while Ben uses the screen. Renders into temp/screens as
// `family_<name>_*.png`. Run from apps/ferret:
//
//   flutter test test/screens/family_screens_test.dart
@Tags(['screens'])
library;

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  _PrivateSample sample,
);

final _screens = <String, _Script>{
  'this_device': (tester, rig, sample) async {
    await rig.open(tester, const ThisDeviceSettingsPage());
  },
  'this_device_only_me': (tester, rig, sample) async {
    await rig.open(tester, const ThisDeviceSettingsPage());
    await tester.tap(find.text('Only me'));
    await rig.settle(tester);
  },
  'previews': (tester, rig, sample) async {
    final phoneId = await rig.pairConnectedPhone(
      tester,
      phoneFeatures: phoneFeatures(),
      name: 'Pixel 7',
    );
    await rig.open(tester, DeviceAccessPage(deviceId: phoneId ?? ''));
    await tester.scrollUntilVisible(
      find.textContaining('Show previews on '),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await rig.settle(tester);
  },
  'home_covered': (tester, rig, sample) async {
    final phoneId = await rig.pairConnectedPhone(
      tester,
      phoneFeatures: phoneFeatures(),
      name: 'Pixel 7',
    );
    sample.deviceId = phoneId ?? '';
    await rig.settle(tester);
  },
};

void main() {
  setUpAll(loadScreenFonts);

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final size in const [popover, phone]) {
      for (final brightness in Brightness.values) {
        if (brightness == .dark && !size.darkToo) {
          continue;
        }

        testWidgets('family $name ${size.name} ${brightness.name}', (
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
            final sample = _PrivateSample();
            final rig = await ScreenRig.create(
              tester,
              features: [
                ...appFeatures(),
                if (name == 'home_covered') sample,
              ],
              name: 'Family iMac (Anna)',
              tipsDone: true,
            );
            await tester.runAsync(
              () => rig.engine.settings.set(SharedComputer.sharedKey, true),
            );
            await rig.show(tester);
            await script(tester, rig, sample);
            await rig.capture(tester, 'family_$name', size, brightness);
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

/// A text and a notification from the paired phone, both private, as the
/// messages and notifications features mark theirs.
class _PrivateSample extends FeatureUi {
  String deviceId = '';

  @override
  String get featureId => 'screens.private';

  @override
  final Feature feature = _NoFeature();

  @override
  String title(BuildContext context) => 'Private';

  @override
  IconData get icon => LucideIcons.lock;

  @override
  bool hasHomeCard(FeatureContext feature) => false;

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) {
    if (deviceId.isEmpty) {
      return const [];
    }

    final now = DateTime.now();
    return [
      ActivityItem(
        id: 'text',
        icon: LucideIcons.messageSquare,
        title: 'Mom · Pixel 7',
        detail: 'Did you book the dentist?',
        at: now.subtract(const Duration(minutes: 1)),
        deviceId: deviceId,
        private: PrivateContent(deviceId, cover: 'New text on Pixel 7'),
      ),
      ActivityItem(
        id: 'notification',
        icon: LucideIcons.bell,
        title: 'Bank: Payment received',
        detail: '€1,250.00 from Employer Ltd',
        at: now.subtract(const Duration(minutes: 4)),
        deviceId: deviceId,
        private: PrivateContent(
          deviceId,
          cover: 'New notification from Pixel 7',
        ),
      ),
    ];
  }
}

class _NoFeature extends Feature {
  @override
  String get id => 'screens.private';

  @override
  Future<Null> onEnvelope(Session session, Envelope envelope) async => null;
}
