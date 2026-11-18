import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart' hide Key;
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

void main() {
  late FakeHost host;
  late FakeInjector injector;
  late RemoteInputFeatureUi ui;

  Future<void> start(
    WidgetTester tester, {
    bool computer = true,
    InjectorStatus status = const .ready(.quartz),
    Map<String, Object?>? settings,
  }) async {
    await tester.runAsync(() async {
      host = await FakeHost.create(settings: settings);
      injector = FakeInjector(statusNow: status);
      ui = RemoteInputFeatureUi(
        feature: RemoteInputFeature(
          injector: () => injector,
          canBeControlled: computer,
          canControl: !computer,
          requestTimeout: const Duration(milliseconds: 10),
        ),
      );
      await ui.feature.start(host);
    });
    addTearDown(() => tester.runAsync(ui.feature.stop));
  }

  Future<BuildContext> contextOf(WidgetTester tester) async {
    await tester.pumpWidget(testApp(const SizedBox.shrink()));
    return tester.element(find.byType(SizedBox).first);
  }

  DeviceStatus statusOf(FakeSession session) => DeviceStatus(
    TrustedDevice(
      id: session.remoteDeviceId,
      name: session.name,
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: Uint8List(0),
      pairedAt: DateTime(2026),
    ),
    session,
  );

  FakeSession phone() => FakeSession(
    'pixel',
    name: 'Pixel 9',
    flags: const [RemoteInputFeature.controllerFlag],
  );

  group('settings parts', () {
    testWidgets('a computer that can be controlled reads On under Control', (
      tester,
    ) async {
      await start(tester);

      final part = ui
          .settingsSections(await contextOf(tester), _context)
          .single;

      expect(part.group, SettingsGroup.control);
      expect(part.title, 'Pointer and keyboard');
      expect(part.summary, 'On');
      expect(part.isOn, isTrue);
      expect(part.needsAttention, isFalse);
    });

    testWidgets('access that was never given is not a problem', (tester) async {
      await start(tester, status: const .needsPermission(.quartz));

      final part = ui
          .settingsSections(await contextOf(tester), _context)
          .single;

      expect(part.summary, 'Needs access');
      expect(part.isOn, isFalse);
      expect(part.needsAttention, isFalse);
    });

    testWidgets('a check that could not run is not a problem either', (
      tester,
    ) async {
      await start(tester, status: const .unavailable(.failed));

      final part = ui
          .settingsSections(await contextOf(tester), _context)
          .single;

      expect(part.summary, 'Not available yet');
      expect(part.needsAttention, isFalse);
    });

    testWidgets('access that went away needs attention, and says so when it '
        'changes', (tester) async {
      await start(tester);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      injector.statusNow = const .needsPermission(.quartz);
      await tester.runAsync(() async {
        await ui.feature.controlHost?.refreshStatus();
        await settle();
      });
      final part = ui
          .settingsSections(await contextOf(tester), _context)
          .single;

      expect(changes, greaterThan(0));
      expect(part.summary, 'Needs access');
      expect(part.needsAttention, isTrue);
    });

    testWidgets('turned off is Off, and no problem even without access', (
      tester,
    ) async {
      await start(
        tester,
        status: const .needsPermission(.quartz),
        settings: {
          RemoteInputSettings.enabledKey: false,
          RemoteInputSettings.hadAccessKey: true,
        },
      );

      final part = ui
          .settingsSections(await contextOf(tester), _context)
          .single;

      expect(part.summary, 'Off');
      expect(part.isOn, isFalse);
      expect(part.needsAttention, isFalse);
    });

    testWidgets('a phone gets its touchpad settings, with no on and off', (
      tester,
    ) async {
      await start(tester, computer: false);

      final part = ui
          .settingsSections(await contextOf(tester), _context)
          .single;

      expect(part.group, SettingsGroup.control);
      expect(part.title, 'Touchpad');
      expect(part.isOn, isNull);
      expect(part.needsAttention, isFalse);
    });
  });

  group('what a device may do', () {
    testWidgets('a phone gets a switch that names this computer', (
      tester,
    ) async {
      await start(tester);
      final context = await contextOf(tester);

      final permission = ui
          .devicePermissions(context, _context, statusOf(phone()))
          .single;

      expect(permission.label, 'Control this computer without asking');
      expect(permission.value, isFalse);

      await tester.runAsync(() async {
        permission.onChanged(true);
        await settle();
      });
      final allowed = ui
          .devicePermissions(context, _context, statusOf(phone()))
          .single;

      expect(ui.feature.settings.allowedDevices, ['pixel']);
      expect(allowed.value, isTrue);
    });

    testWidgets('on a Mac it says this Mac', (tester) async {
      await start(tester);
      debugDefaultTargetPlatformOverride = .macOS;

      final permission = ui
          .devicePermissions(
            await contextOf(tester),
            _context,
            statusOf(phone()),
          )
          .single;
      debugDefaultTargetPlatformOverride = null;

      expect(permission.label, 'Control this Mac without asking');
    });

    testWidgets('turning it off also ends that phone\'s control', (
      tester,
    ) async {
      await start(tester);
      final pixel = phone();
      host.sessions = [pixel];
      await tester.runAsync(() async {
        await ui.feature.controlHost?.onRequest(
          pixel,
          ControlRequest(version: 1),
        );
        await ui.feature.controlHost?.answer(.always);
      });
      final permission = ui
          .devicePermissions(await contextOf(tester), _context, statusOf(pixel))
          .single;

      await tester.runAsync(() async {
        permission.onChanged(false);
        await settle();
      });

      expect(permission.value, isTrue);
      expect(ui.feature.settings.allowedDevices, isEmpty);
      expect(ui.feature.controlHost?.active, isNull);
    });

    testWidgets('says where to turn control on while it is off', (
      tester,
    ) async {
      await start(tester, settings: {RemoteInputSettings.enabledKey: false});

      final permission = ui
          .devicePermissions(
            await contextOf(tester),
            _context,
            statusOf(phone()),
          )
          .single;

      expect(permission.detail, contains('Settings → Control'));
    });

    testWidgets('another computer gets no switch, and neither does anything '
        'on a phone', (tester) async {
      await start(tester);
      final context = await contextOf(tester);
      final computer = FakeSession('imac', name: 'iMac');

      expect(
        ui.devicePermissions(context, _context, statusOf(computer)),
        isEmpty,
      );

      await start(tester, computer: false);
      expect(
        ui.devicePermissions(context, _context, statusOf(computer)),
        isEmpty,
      );
    });
  });

  group('health on a device page', () {
    testWidgets('on a computer, a phone asks first until it is always '
        'allowed', (tester) async {
      await start(tester);
      final pixel = phone();

      final asks = ui.healthFor(_context, statusOf(pixel));
      await tester.runAsync(() => ui.feature.settings.allow('pixel'));
      final always = ui.healthFor(_context, statusOf(pixel));

      expect(asks?.state, FeatureHealthState.ok);
      expect(asks?.reason, 'Asks before it controls this computer');
      expect(always?.reason, 'May control this computer without asking');
    });

    testWidgets('on a computer where it is off, says where to turn it on', (
      tester,
    ) async {
      await start(tester, settings: {RemoteInputSettings.enabledKey: false});

      final health = ui.healthFor(_context, statusOf(phone()));

      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Off on this computer');
      expect(health?.help, startsWith('Open Settings → Control'));
    });

    testWidgets('on a computer without access, offers to allow it: quiet '
        'when never given, a warning when lost', (tester) async {
      await start(tester, status: const .needsPermission(.quartz));

      final never = ui.healthFor(_context, statusOf(phone()));
      never?.onFix?.call();
      await tester.runAsync(settle);

      expect(never?.state, FeatureHealthState.off);
      expect(never?.onFix, isNotNull);
      expect(injector.requests, 1);

      await start(
        tester,
        status: const .needsPermission(.quartz),
        settings: {RemoteInputSettings.hadAccessKey: true},
      );
      final lost = ui.healthFor(_context, statusOf(phone()));

      expect(lost?.state, FeatureHealthState.needsAttention);
    });

    testWidgets('on a phone, a computer it can control is ready', (
      tester,
    ) async {
      await start(tester, computer: false);
      final mac = FakeSession('mac', name: 'MacBook Air');

      final health = ui.healthFor(_context, statusOf(mac));

      expect(health?.state, FeatureHealthState.ok);
      expect(health?.reason, 'Asks on MacBook Air first');
    });

    testWidgets('on a phone, a computer that turned it off says where to '
        'turn it on there', (tester) async {
      await start(tester, computer: false);
      final mac = FakeSession(
        'mac',
        name: 'MacBook Air',
        answer: (_) => ControlDeny(reason: .DENY_REASON_TURNED_OFF),
      );
      host.sessions = [mac];
      await tester.runAsync(() => ui.feature.control('mac'));

      final health = ui.healthFor(_context, statusOf(mac));

      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Off on MacBook Air');
      expect(
        health?.help,
        startsWith('On MacBook Air: open Ferret → Settings → Control'),
      );
    });

    testWidgets('on a phone, a computer without access needs attention', (
      tester,
    ) async {
      await start(tester, computer: false);
      final mac = FakeSession(
        'mac',
        name: 'MacBook Air',
        answer: (_) => ControlDeny(reason: .DENY_REASON_NEEDS_PERMISSION),
      );
      host.sessions = [mac];
      await tester.runAsync(() => ui.feature.control('mac'));

      final health = ui.healthFor(_context, statusOf(mac));

      expect(health?.state, FeatureHealthState.needsAttention);
      expect(health?.help, contains('Allow access'));
    });

    testWidgets('does not apply between two computers, or offline', (
      tester,
    ) async {
      await start(tester);
      final computer = FakeSession('imac', name: 'iMac');

      expect(ui.healthFor(_context, statusOf(computer)), isNull);
      expect(
        ui.healthFor(
          _context,
          DeviceStatus(statusOf(computer).device, null),
        ),
        isNull,
      );
    });
  });
}

final _context = _NoContext();

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
