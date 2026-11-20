import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart' hide Key;
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/remote_input.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

void main() {
  late FakeHost host;
  late FakeCapture capture;
  late RemoteInputFeatureUi ui;

  Future<void> start(
    WidgetTester tester, {
    Map<String, Object?>? settings,
    CaptureAccess access = const CaptureAccess(
      inputMonitoring: true,
      accessibility: true,
    ),
  }) async {
    await tester.runAsync(() async {
      host = await FakeHost.create(settings: settings);
      capture = FakeCapture(accessNow: access);
      ui = RemoteInputFeatureUi(
        feature: RemoteInputFeature(
          injector: FakeInjector.new,
          locker: const UnsupportedScreenLocker(),
          canBeControlled: true,
          canControl: false,
          canSwitchScreens: true,
          capture: () => capture,
        ),
      );
      await ui.feature.start(host);
    });
    addTearDown(() => tester.runAsync(ui.feature.stop));
  }

  Future<void> showSettings(WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: ui.screenViewModel,
          child: const ScreenSwitchSettingsFrame(),
        ),
      ),
    );
    await tester.pump();
  }

  DeviceStatus statusOf(FakeSession session) => DeviceStatus(
    TrustedDevice(
      id: session.remoteDeviceId,
      name: session.name,
      platform: .PLATFORM_WINDOWS,
      formFactor: .FORM_FACTOR_DESKTOP,
      publicKey: Uint8List(0),
      pairedAt: DateTime(2026),
    ),
    session,
  );

  FakeSession pc() => FakeSession(
    'pc',
    name: 'Desk PC',
    flags: const [
      RemoteInputFeature.controlFlag,
      RemoteInputFeature.screenFlag,
    ],
  );

  testWidgets('off by default, and the switch keys wait until it is on', (
    tester,
  ) async {
    await start(tester);
    await showSettings(tester);

    expect(
      find.text("Use this Mac's keyboard and mouse on my other computers"),
      findsOneWidget,
    );
    expect(find.textContaining('⌃⌥→ sends them'), findsOneWidget);
    expect(capture.switchKeysOn, isNull);
    expect(
      find.text('On. Uses Input Monitoring and Accessibility.'),
      findsNothing,
    );
  });

  testWidgets('turning it on takes the keys and says it is ready', (
    tester,
  ) async {
    await start(tester);
    await showSettings(tester);

    await tester.tap(find.byType(SwitchToggle));
    await pumpAll(tester);

    expect(ui.feature.settings.screenSwitch, isTrue);
    expect(capture.switchKeysOn, isTrue);
    expect(
      find.text('On. Uses Input Monitoring and Accessibility.'),
      findsOneWidget,
    );
  });

  testWidgets('missing access asks right away and offers to allow it', (
    tester,
  ) async {
    await start(
      tester,
      access: const CaptureAccess(inputMonitoring: false, accessibility: true),
    );
    await showSettings(tester);

    await tester.tap(find.byType(SwitchToggle));
    await pumpAll(tester);

    expect(capture.requests, 1);
    expect(
      find.text('Needs Input Monitoring and Accessibility'),
      findsOneWidget,
    );
    final part = ui.settingsSections(
      tester.element(find.byType(ScreenSwitchSettingsFrame)),
      _context,
    );
    expect(part.map((part) => part.title), contains('One keyboard and mouse'));
    expect(
      part
          .singleWhere((part) => part.title == 'One keyboard and mouse')
          .needsAttention,
      isTrue,
    );

    await tester.tap(find.text('Allow access'));
    await pumpAll(tester);
    expect(capture.settingsOpened, 1);
  });

  testWidgets('another app holding the keys is said plainly', (tester) async {
    await start(tester, settings: {RemoteInputSettings.screenSwitchKey: true});
    await tester.runAsync(() async {
      await ui.feature.settings.setScreenSwitch(false);
      capture.keysRegistered = false;
      await ui.feature.settings.setScreenSwitch(true);
      await settle();
    });
    await showSettings(tester);

    expect(
      find.text('Another app uses ⌃⌥→ or ⌃⌥⎋, so they don\'t reach Ferret.'),
      findsOneWidget,
    );
  });

  testWidgets('the switch keys are listed only while it is on', (
    tester,
  ) async {
    await start(tester);
    Future<List<FeatureShortcut>> listed() async {
      var shortcuts = <FeatureShortcut>[];
      await tester.pumpWidget(
        KeyedSubtree(
          key: UniqueKey(),
          child: testApp(
            Builder(
              builder: (context) {
                shortcuts = ui.globalShortcuts(context, _context);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      return shortcuts;
    }

    expect(await listed(), isEmpty);

    await tester.runAsync(() => ui.feature.settings.setScreenSwitch(true));
    final shortcuts = await listed();
    expect(shortcuts.map((shortcut) => shortcut.keys), ['⌃⌥→', '⌃⌥⎋']);
    expect(shortcuts.first.label, 'Keyboard and mouse to the next computer');
  });

  testWidgets('a computer that takes the keyboard shows the keys on its '
      'page', (tester) async {
    await start(tester, settings: {RemoteInputSettings.screenSwitchKey: true});

    final health = ui.healthFor(_context, statusOf(pc()));
    expect(health?.state, FeatureHealthState.ok);
    expect(
      health?.reason,
      '⌃⌥→ to the next computer, ⌃⌥⎋ back here',
    );

    await tester.runAsync(
      () => ui.feature.settings.setScreenSwitch(false),
    );
    final off = ui.healthFor(_context, statusOf(pc()));
    expect(off?.state, FeatureHealthState.off);
    expect(off?.help, contains('Settings → Control'));
  });

  testWidgets('Activity pins where the keyboard is, with a way back, then '
      'says why it came back', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await start(tester, settings: {RemoteInputSettings.screenSwitchKey: true});
    final session = pc()
      ..answer = (_) => ControlGrant(version: 1, always: true);
    host.sessions = [session];
    final l10n = lookupRemoteInputLocalizations(const Locale('en'));

    await tester.runAsync(() async {
      await ui.feature.screenSwitch?.next();
      await settle();
    });
    final away = screenSwitchActivity(l10n, ui.screenViewModel).single;
    expect(away.title, 'Keyboard and mouse on Desk PC');
    expect(away.detail, '⌃⌥⎋ brings them back');
    expect(away.pinned, isTrue);
    expect(away.actions.single.label, 'Bring back');

    await tester.runAsync(() async {
      ui.feature.onSessionClosed(session);
      await settle();
    });
    final lost = screenSwitchActivity(l10n, ui.screenViewModel).single;
    expect(lost.title, 'Lost Desk PC');
    expect(lost.detail, 'Your keyboard and mouse are back on this Mac.');
    expect(capture.capturing, isFalse);

    lost.onDismiss?.call();
    expect(screenSwitchActivity(l10n, ui.screenViewModel), isEmpty);
  });

  testWidgets('a phone gets no keyboard hint', (tester) async {
    await start(tester, settings: {RemoteInputSettings.screenSwitchKey: true});

    expect(
      ui.healthFor(_context, statusOf(FakeSession('pixel', flags: const []))),
      isNull,
    );
  });
}

/// Past the switch's 150 ms before it answers, then whatever follows.
Future<void> pumpAll(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
  await tester.runAsync(settle);
  await tester.pump();
}

final _context = _NoContext();

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
