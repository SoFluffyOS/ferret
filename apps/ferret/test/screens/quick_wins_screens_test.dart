// The quick wins from temp/research/feature_gaps.md: Recent clips, battery
// on device rows, Lock this computer and the presentation remote. Renders
// into temp/screens as `quick_<name>_*.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/quick_wins_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/clipboard.dart';
import 'package:protocol/protocol.dart';
import 'package:remote_input/remote_input.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  List<FeatureUi> features,
);

/// Never the real screen locker: a render must not lock this Mac.
class _NoLock implements ScreenLocker {
  @override
  bool get isSupported => true;

  @override
  Future<bool> lock() async => false;
}

/// Takes input and does nothing with it, so a render never moves this
/// Mac's pointer.
class _NoInput implements InputInjector {
  @override
  Future<InjectorStatus> status() async => const .ready(.quartz);

  @override
  Future<InjectorStatus> requestAccess() => status();

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<void> inject(List<InputAction> actions) async {}

  @override
  Future<void> releaseAll() async {}

  @override
  Future<void> dispose() async {}
}

/// The app's features with a remote input that can't lock for real, as a
/// computer ([asPhone] false) or a phone.
List<FeatureUi> _safeFeatures({bool asPhone = false}) => [
  for (final feature in appFeatures())
    switch (feature) {
      RemoteInputFeatureUi() => RemoteInputFeatureUi(
        feature: RemoteInputFeature(
          injector: _NoInput.new,
          locker: _NoLock(),
          canBeControlled: !asPhone,
          canControl: asPhone,
        ),
      ),
      _ => feature,
    },
];

/// Screens that run as a phone paired with a Mac.
const _phoneScreens = {'lock_row', 'presentation'};

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
  'webcam_row': (tester, rig, features) async {
    final phoneId =
        await rig.pairConnectedPhone(
          tester,
          phoneFeatures: phoneFeatures(),
          name: 'Pixel 7',
        ) ??
        '';
    await rig.open(tester, DevicePage(deviceId: phoneId));
    await tester.scrollUntilVisible(
      find.text('Use Pixel 7 as a webcam'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await rig.settle(tester);
  },
  'lock_consent': (tester, rig, features) async {
    final phoneId =
        await rig.pairConnectedPhone(
          tester,
          phoneFeatures: phoneFeatures(),
          name: 'Pixel 7',
        ) ??
        '';
    final session = rig.engine.sessionFor(phoneId);
    final host = features
        .whereType<RemoteInputFeatureUi>()
        .single
        .feature
        .controlHost;
    if (session != null) {
      unawaited(host?.onLockRequest(session));
    }
    await rig.settle(tester);
  },
  'lock_row': (tester, rig, features) async {
    final computerId =
        await rig.pairConnectedComputer(
          tester,
          computerFeatures: _safeFeatures(),
        ) ??
        '';
    final remote = features.whereType<RemoteInputFeatureUi>().single;
    unawaited(remote.feature.lockDevice(computerId));
    await rig.open(tester, DevicePage(deviceId: computerId));
  },
  'presentation': (tester, rig, features) async {
    final computerFeatures = _safeFeatures();
    final computer = computerFeatures.whereType<RemoteInputFeatureUi>().single;
    final computerId =
        await rig.pairConnectedComputer(
          tester,
          computerFeatures: computerFeatures,
        ) ??
        '';
    await tester.runAsync(
      () => computer.feature.settings.allow(rig.engine.identity.deviceId),
    );
    final remote = features.whereType<RemoteInputFeatureUi>().single;
    final home = tester.element(find.byType(HomePage));
    final status = rig.engine.devices.firstWhere(
      (status) => status.device.id == computerId,
    );
    remote
        .deviceActions(home, rig.featureContext, status)
        .firstWhere((action) => action.id == 'remote_input.present')
        .onPressed
        ?.call();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await rig.settle(tester);
  },
  'battery': (tester, rig, features) async {
    await rig.pairConnectedPhone(
      tester,
      phoneFeatures: phoneFeatures(),
      name: 'Pixel 7',
    );
    await tester.runAsync(() async {
      await rig.others.last.updatePresence(
        Presence(userActive: true, batteryPercent: 62, charging: true),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await rig.settle(tester);
  },
  'battery_low': (tester, rig, features) async {
    await rig.pairConnectedPhone(
      tester,
      phoneFeatures: phoneFeatures(),
      name: 'Pixel 7',
    );
    await tester.runAsync(() async {
      await rig.others.last.updatePresence(
        Presence(userActive: true, batteryPercent: 14),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await rig.settle(tester);
  },
  'webcam_help': (tester, rig, features) async {
    await rig.open(
      tester,
      const WebcamHelpPage(deviceName: 'Pixel 7', here: 'mac'),
    );
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
            final asPhone = _phoneScreens.contains(name);
            final features = _safeFeatures(asPhone: asPhone);
            final rig = await ScreenRig.create(
              tester,
              features: features,
              name: 'MacBook Air',
              tipsDone: true,
              asPhone: asPhone,
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
