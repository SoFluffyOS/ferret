// One keyboard and mouse for several computers: the Settings line, the keys
// on the Keyboard shortcuts page and on a computer's page, Activity while
// they are away or came back, and the question on the computer that
// receives them. Renders into temp/screens
// as `keyboard_<name>_<size>_<mode>.png`. Run from apps/ferret:
//
//   fvm flutter test test/screens/keyboard_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/remote_input.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures;
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  _Macs macs,
);

const _window = CaptureSize('window', 1000, 720);

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

/// Never this Mac's event tap: a render must not take its keyboard.
class _NoCapture implements InputCapture {
  _NoCapture({this.granted = true});

  final bool granted;
  final StreamController<NativeCaptureEnd> _ends = .broadcast();

  void end(NativeCaptureEnd reason) => _ends.add(reason);

  @override
  Future<CaptureAccess> access() async =>
      CaptureAccess(inputMonitoring: granted, accessibility: true);

  @override
  Future<CaptureAccess> requestAccess() => access();

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<bool> secureInputOn() async => false;

  @override
  Future<bool> setSwitchKeys({required bool enabled}) async => true;

  @override
  Future<Set<KeyModifier>?> start() async => const {};

  @override
  Future<void> stop() async {}

  @override
  Stream<List<NativeCapturedEvent>> get events => const Stream.empty();

  @override
  Stream<NativeSwitchKey> get switchKeys => const Stream.empty();

  @override
  Stream<NativeCaptureEnd> get ends => _ends.stream;
}

/// This Mac ([here]) and the other one ([there]), each with its own
/// harmless capture.
class _Macs {
  _Macs({bool granted = true})
    : hereCapture = _NoCapture(granted: granted),
      thereCapture = _NoCapture();

  final _NoCapture hereCapture;
  final _NoCapture thereCapture;
  late final List<FeatureUi> hereFeatures = _features(hereCapture);
  late final List<FeatureUi> thereFeatures = _features(thereCapture);

  RemoteInputFeature get here => _remote(hereFeatures);

  RemoteInputFeature get there => _remote(thereFeatures);

  static RemoteInputFeature _remote(List<FeatureUi> features) =>
      features.whereType<RemoteInputFeatureUi>().single.feature;

  static List<FeatureUi> _features(InputCapture capture) => [
    for (final feature in appFeatures())
      switch (feature) {
        RemoteInputFeatureUi() => RemoteInputFeatureUi(
          feature: RemoteInputFeature(
            injector: _NoInput.new,
            canBeControlled: true,
            canControl: false,
            canSwitchScreens: true,
            capture: () => capture,
          ),
        ),
        _ => feature,
      },
  ];
}

Future<String> _pairOther(
  WidgetTester tester,
  ScreenRig rig,
  _Macs macs,
) async =>
    await rig.pairConnectedComputer(
      tester,
      computerFeatures: macs.thereFeatures,
    ) ??
    '';

/// Sends this Mac's keyboard and mouse to the other one, which allowed it
/// before.
Future<void> _goAway(WidgetTester tester, ScreenRig rig, _Macs macs) async {
  await _pairOther(tester, rig, macs);
  await tester.runAsync(() async {
    await macs.there.settings.allow(rig.engine.identity.deviceId);
    await macs.here.screenSwitch?.setEnabled(true);
    await macs.here.screenSwitch?.next();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await rig.settle(tester);
}

/// Settings → Control, scrolled to the One keyboard and mouse part.
Future<void> _openKeyboardSettings(WidgetTester tester, ScreenRig rig) async {
  await rig.open(tester, const SettingsGroupPage(group: .control));
  await tester.scrollUntilVisible(
    find.text("Use this Mac's keyboard and mouse on my other computers"),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
  await rig.settle(tester);
}

final _screens = <String, _Script>{
  'settings': (tester, rig, macs) async {
    await tester.runAsync(() async {
      await macs.here.screenSwitch?.setEnabled(true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await _openKeyboardSettings(tester, rig);
  },
  'settings_access': (tester, rig, macs) async {
    await tester.runAsync(() async {
      await macs.here.screenSwitch?.setEnabled(true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await _openKeyboardSettings(tester, rig);
  },
  'shortcuts': (tester, rig, macs) async {
    await tester.runAsync(() async {
      await macs.here.screenSwitch?.setEnabled(true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await rig.open(
      tester,
      Provider<FerretMenubar?>.value(
        value: FerretMenubar(),
        child: const KeyboardShortcutsPage(),
      ),
    );
  },
  'device': (tester, rig, macs) async {
    final otherId = await _pairOther(tester, rig, macs);
    await tester.runAsync(() async {
      await macs.here.screenSwitch?.setEnabled(true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await rig.open(tester, DevicePage(deviceId: otherId));
    final hint = find.text('⌃⌥→ to the next computer, ⌃⌥⎋ back here').first;
    await tester.scrollUntilVisible(
      hint,
      300,
      scrollable: find
          .ancestor(
            of: find.textContaining('What works with').first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.drag(
      find.ancestor(of: hint, matching: find.byType(Scrollable)).first,
      const Offset(0, -300),
    );
    await rig.settle(tester);
  },
  'away': _goAway,
  'password_field': (tester, rig, macs) async {
    await _goAway(tester, rig, macs);
    await tester.runAsync(() async {
      macs.hereCapture.end(.secureInput);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await rig.settle(tester);
  },
  'consent': (tester, rig, macs) async {
    await _pairOther(tester, rig, macs);
    await tester.runAsync(() async {
      await macs.there.screenSwitch?.setEnabled(true);
      unawaited(macs.there.screenSwitch?.next());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await rig.settle(tester);
  },
};

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    for (final size in [popover, _window]) {
      for (final brightness in Brightness.values) {
        testWidgets('keyboard $name ${size.name} ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, size, brightness);
          mockPlugins(tester);
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          final reportError = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains('overflowed')) {
              return;
            }

            reportError?.call(details);
          };
          try {
            final macs = _Macs(granted: name != 'settings_access');
            final rig = await ScreenRig.create(
              tester,
              features: macs.hereFeatures,
              name: 'iMac',
              tipsDone: true,
            );
            await rig.show(tester);
            await script(tester, rig, macs);
            await rig.capture(tester, 'keyboard_$name', size, brightness);
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
