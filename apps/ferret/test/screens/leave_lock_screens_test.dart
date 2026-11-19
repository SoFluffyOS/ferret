// Locking the computer when a phone leaves. Renders into temp/screens as
// `leave_lock_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/leave_lock_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'package:actions/actions.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/action_fakes.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  ActionsFeature actions,
);

/// The app's features, with a lock that waits milliseconds instead of
/// minutes and never touches this Mac.
List<FeatureUi> _features(ActionsFeature actions) => [
  ActionsFeatureUi(feature: actions),
  ...appFeatures().where((feature) => feature is! ActionsFeatureUi),
];

Future<String> _pairPixel(
  WidgetTester tester,
  ScreenRig rig,
  ActionsFeature actions,
) async {
  final phoneId =
      await rig.pairConnectedPhone(
        tester,
        phoneFeatures: phoneFeatures(),
        name: 'Pixel 7',
      ) ??
      '';
  await tester.runAsync(
    () => actions.settings.setLocksWhenGone(phoneId, locks: true),
  );
  await rig.settle(tester);

  return phoneId;
}

/// The phone as its session ends without a goodbye.
class _DroppedSession extends Fake implements Session {
  _DroppedSession(this.remoteDeviceId);

  @override
  final String remoteDeviceId;

  @override
  GoodbyeReason? get remoteGoodbye => null;
}

/// Takes the phone away, then tells the lock it dropped without a goodbye:
/// a real drop reads as Reconnecting… for about 45 seconds first, too long
/// for a render.
Future<void> _leave(
  WidgetTester tester,
  ScreenRig rig,
  ActionsFeature actions,
  String phoneId,
) async {
  await rig.disconnectOthers(tester);
  actions.leaveLock?.onSessionClosed(_DroppedSession(phoneId));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await rig.settle(tester);
}

final _screens = <String, (_Script, Duration)>{
  'setting': (
    (tester, rig, actions) async {
      await _pairPixel(tester, rig, actions);
      await rig.open(tester, const SettingsGroupPage(group: .control));
      await tester.scrollUntilVisible(
        find.text('Lock when your phone leaves'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.runAsync(
        () => Scrollable.ensureVisible(
          tester.element(find.text('Lock when your phone leaves')),
          alignment: 0.05,
        ),
      );
      await tester.drag(find.byType(Scrollable).last, const Offset(0, 160));
      await rig.settle(tester);
    },
    const Duration(seconds: 10),
  ),
  'device': (
    (tester, rig, actions) async {
      final phoneId = await _pairPixel(tester, rig, actions);
      await rig.open(tester, DevicePage(deviceId: phoneId));
      await tester.scrollUntilVisible(
        find.textContaining('when Pixel 7 leaves'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await rig.settle(tester);
    },
    const Duration(seconds: 10),
  ),
  'countdown': (
    (tester, rig, actions) async {
      final phoneId = await _pairPixel(tester, rig, actions);
      await _leave(tester, rig, actions, phoneId);
    },
    const Duration(seconds: 10),
  ),
  'activity': (
    (tester, rig, actions) async {
      final phoneId = await _pairPixel(tester, rig, actions);
      await _leave(tester, rig, actions, phoneId);
      await rig.open(tester, const ActivityPage());
    },
    const Duration(milliseconds: 100),
  ),
};

void main() {
  setUpAll(loadScreenFonts);

  for (final MapEntry(key: name, value: (script, countdown))
      in _screens.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('leave lock $name ${brightness.name}', (tester) async {
        setScreen(tester, popover, brightness);
        mockPlugins(tester);
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = popover.platform;
        final reportError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('overflowed')) {
            return;
          }

          reportError?.call(details);
        };
        try {
          final actions = safeActionsFeature(
            lockMinute: const Duration(milliseconds: 50),
            countdownLength: countdown,
          );
          final rig = await ScreenRig.create(
            tester,
            features: _features(actions),
            name: 'MacBook Air',
            tipsDone: true,
          );
          await rig.show(tester);
          await script(tester, rig, actions);
          await rig.capture(tester, 'leave_lock_$name', popover, brightness);
          actions.leaveLock?.cancel();
          await rig.settle(tester);
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
