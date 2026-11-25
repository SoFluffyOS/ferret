// Computer actions and the Android "start with the phone" question. Renders
// into temp/screens as `actions_<name>_*.png`. Run from apps/ferret:
//
//   flutter test test/screens/actions_screens_test.dart
// ignore_for_file: depend_on_referenced_packages
@Tags(['screens'])
library;

import 'dart:async';

import 'package:actions/actions.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:protocol/actions.dart';
import 'package:shell/shell.dart';

import 'screens_test.dart' show appFeatures, phoneFeatures;
import 'support/action_fakes.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';

typedef _Script = Future<void> Function(
  WidgetTester tester,
  ScreenRig rig,
  List<FeatureUi> features,
);

/// Screens that run as a phone paired with a Mac.
const _phoneScreens = {
  'phone_group',
  'phone_own_only',
  'phone_confirm',
  'boot_ask',
};

/// An Android phone that already lets Ferret run in the background, so the
/// card holds only its question.
class _AllowedPhone extends Fake implements FerretSystem {
  @override
  bool get isAndroid => true;

  @override
  Future<bool> areNotificationsAllowed() async => true;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;

  @override
  Future<bool> isBackgroundRestricted() async => false;

  @override
  Future<DeviceMaker> deviceMaker() async => .other;

  @override
  Future<int> serviceStopsToday({DateTime? now}) async => 0;

  @override
  Future<bool> canRequestAddTile() async => false;
}

ActionsHost? _hostOf(List<FeatureUi> features) =>
    features.whereType<ActionsFeatureUi>().single.feature.actionsHost;

Future<String> _pairPixel(WidgetTester tester, ScreenRig rig) async =>
    await rig.pairConnectedPhone(
      tester,
      phoneFeatures: phoneFeatures(),
      name: 'Pixel 7',
    ) ??
    '';

/// Pairs a Mac that offers its actions and two of its owner's own.
Future<String> _pairMac(WidgetTester tester, ScreenRig rig) async {
  final computerFeatures = appFeatures();
  final computerId =
      await rig.pairConnectedComputer(
        tester,
        computerFeatures: computerFeatures,
      ) ??
      '';
  final host = _hostOf(computerFeatures);
  await tester.runAsync(() async {
    await host?.addCustom(
      name: 'Good night',
      commandLine: 'shortcuts run "Good night"',
    );
    await host?.addCustom(
      name: 'Back up photos',
      commandLine: '~/bin/backup-photos.sh',
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });

  return computerId;
}

/// Pairs a computer whose platform offers no built-in actions, with one
/// action of its owner's.
Future<String> _pairOwnOnly(WidgetTester tester, ScreenRig rig) async {
  final computerFeatures = [
    for (final feature in appFeatures())
      switch (feature) {
        ActionsFeatureUi() => ActionsFeatureUi(
          feature: safeActionsFeature(
            computer: const NothingBuiltIn(),
            offersActions: true,
          ),
        ),
        _ => feature,
      },
  ];
  final computerId =
      await rig.pairConnectedComputer(
        tester,
        computerFeatures: computerFeatures,
      ) ??
      '';
  await tester.runAsync(() async {
    await _hostOf(computerFeatures)?.addCustom(
      name: 'Say hi',
      commandLine: 'say hi',
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });

  return computerId;
}

void _ask(ScreenRig rig, List<FeatureUi> features, String phoneId, String id) {
  final session = rig.engine.sessionFor(phoneId);
  if (session == null) {
    return;
  }

  unawaited(_hostOf(features)?.onRun(session, RunAction(id: id)));
}

final _screens = <String, _Script>{
  'consent': (tester, rig, features) async {
    final phoneId = await _pairPixel(tester, rig);
    _ask(rig, features, phoneId, ActionIds.restart);
    await rig.settle(tester);
  },
  'consent_custom': (tester, rig, features) async {
    final phoneId = await _pairPixel(tester, rig);
    final host = _hostOf(features);
    final backup = await tester.runAsync(
      () async => host?.addCustom(
        name: 'Back up photos',
        commandLine: '~/bin/backup-photos.sh --to "/Volumes/My Disk"',
      ),
    );
    _ask(rig, features, phoneId, backup?.id ?? '');
    await rig.settle(tester);
  },
  'countdown': (tester, rig, features) async {
    final phoneId = await _pairPixel(tester, rig);
    final host = _hostOf(features);
    await tester.runAsync(() async {
      for (final action in host?.grantable ?? const <OfferedAction>[]) {
        await host?.setAllowed(phoneId, action, allowed: true);
      }
    });
    _ask(rig, features, phoneId, ActionIds.shutDown);
    await rig.settle(tester);
  },
  'home_card': (tester, rig, features) async {
    final phoneId = await _pairPixel(tester, rig);
    _ask(rig, features, phoneId, ActionIds.sleep);
    await rig.settle(tester);
    rig.navigator?.pop();
    await rig.settle(tester);
  },
  'settings': (tester, rig, features) async {
    final phoneId = await _pairPixel(tester, rig);
    final host = _hostOf(features);
    final session = rig.engine.sessionFor(phoneId);
    await tester.runAsync(() async {
      final night = await host?.addCustom(
        name: 'Good night',
        commandLine: 'shortcuts run "Good night"',
      );
      await host?.addCustom(
        name: 'Back up photos',
        commandLine: '~/bin/backup-photos.sh',
      );
      for (final action in host?.grantable ?? const <OfferedAction>[]) {
        await host?.setAllowed(phoneId, action, allowed: true);
      }
      if (session != null) {
        await host?.onRun(session, RunAction(id: night?.id ?? ''));
        await host?.onRun(session, RunAction(id: ActionIds.sleep));
      }
    });
    await rig.open(tester, const SettingsGroupPage(group: .control));
    await tester.scrollUntilVisible(
      find.text('Let your devices run actions on this Mac'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await rig.settle(tester);
  },
  'settings_edit': (tester, rig, features) async {
    await rig.open(tester, const SettingsGroupPage(group: .control));
    await tester.scrollUntilVisible(
      find.text('Add action'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Add action'));
    await rig.settle(tester);
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'Good night');
    await tester.enterText(fields.at(1), 'shortcuts run "Good night"');
    await rig.settle(tester);
  },
  'device_switches': (tester, rig, features) async {
    final phoneId = await _pairPixel(tester, rig);
    final host = _hostOf(features);
    await tester.runAsync(() async {
      await host?.addCustom(
        name: 'Good night',
        commandLine: 'shortcuts run "Good night"',
      );
      final sleep = host?.grantable.first;
      if (sleep != null) {
        await host?.setAllowed(phoneId, sleep, allowed: true);
      }
    });
    await rig.open(tester, DevicePage(deviceId: phoneId));
    await tester.scrollUntilVisible(
      find.text('Restart this Mac without asking'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await rig.settle(tester);
  },
  'phone_group': (tester, rig, features) async {
    final computerId = await _pairMac(tester, rig);
    await rig.open(tester, DevicePage(deviceId: computerId));
    await tester.scrollUntilVisible(
      find.text('Power and sound'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Power and sound')),
      alignment: 0.1,
    );
    await rig.settle(tester);
  },
  'phone_own_only': (tester, rig, features) async {
    final computerId = await _pairOwnOnly(tester, rig);
    await rig.open(tester, DevicePage(deviceId: computerId));
    await tester.scrollUntilVisible(
      find.text('Say hi'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('This Mac'), findsNothing);
    await rig.settle(tester);
  },
  'phone_confirm': (tester, rig, features) async {
    final computerId = await _pairMac(tester, rig);
    await rig.open(tester, DevicePage(deviceId: computerId));
    await tester.scrollUntilVisible(
      find.text('Shut down…'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Shut down…'));
    await rig.settle(tester);
  },
  'boot_ask': (tester, rig, features) async {
    await tester.runAsync(
      () => rig.engine.settings.set(BootChoice.answeredKey, false),
    );
    await rig.open(
      tester,
      FerretPage(
        title: 'Ferret',
        backLabel: 'Back',
        children: [StayConnectedCard(system: _AllowedPhone())],
      ),
    );
  },
};

void main() {
  setUpAll(() async {
    await loadScreenFonts();
    await initializeDateFormatting();
  });

  for (final MapEntry(key: name, value: script) in _screens.entries) {
    final asPhone = _phoneScreens.contains(name);
    for (final size in const [popover, phone]) {
      if (asPhone != (size == phone)) {
        continue;
      }

      for (final brightness in Brightness.values) {
        testWidgets('actions $name ${size.name} ${brightness.name}', (
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
              true => phoneFeatures(),
              false => appFeatures(),
            };
            final rig = await ScreenRig.create(
              tester,
              features: features,
              name: 'MacBook Air',
              tipsDone: true,
              asPhone: asPhone,
            );
            await rig.show(tester);
            await script(tester, rig, features);
            await rig.capture(tester, 'actions_$name', size, brightness);
            // A countdown left running would outlive the test.
            _hostOf(features)?.cancelCountdown();
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
}
