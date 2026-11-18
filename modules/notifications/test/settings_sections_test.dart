import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';
import 'package:protocol/protocol.dart' as proto;

import 'support/fakes.dart';
import 'support/test_app.dart';

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('on the phone', () {
    late FakeNotificationSource source;
    late MemorySettingsStore settings;
    late NotificationsFeatureUi ui;
    final featureContext = _NoContext();

    setUp(() async {
      source = FakeNotificationSource()
        ..accessGranted = false
        ..apps = [.new(packageName: signal, name: 'Signal')];
      final feature = NotificationsFeature(source: source);
      settings = MemorySettingsStore();
      await feature.start(SettingsOnlyHost(settings));
      ui = NotificationsFeatureUi.withFeature(feature, access: source);
    });

    tearDown(() => ui.dispose());

    Future<FeatureSettings> section(WidgetTester tester) async {
      await ui.onAppStarted(featureContext);
      await tester.pumpWidget(testApp(const SizedBox()));
      await tester.pumpAndSettle();

      return ui
          .settingsSections(
            tester.element(find.byType(ListView)),
            featureContext,
          )
          .single;
    }

    testWidgets('off until it is set up, and never a warning', (tester) async {
      final part = await section(tester);

      expect(part.group, SettingsGroup.phone);
      expect(part.title, 'Notifications');
      expect(part.isOn, isFalse);
      expect(part.summary, isEmpty);
      expect(part.needsAttention, isFalse);
    });

    testWidgets('on without access needs attention', (tester) async {
      await settings.set(MirrorPreferences.enabledKey, true);

      final part = await section(tester);

      expect(part.isOn, isTrue);
      expect(part.summary, 'Needs access');
      expect(part.needsAttention, isTrue);
    });

    testWidgets('working, it says how many apps', (tester) async {
      source.accessGranted = true;
      await settings.set(MirrorPreferences.enabledKey, true);
      await settings.set(MirrorPreferences.allowedAppsKey, [signal]);

      final part = await section(tester);

      expect(part.isOn, isTrue);
      expect(part.summary, '1 app');
      expect(part.needsAttention, isFalse);
    });
  });

  group('with a phone and a laptop', () {
    late Bus bus;
    late FakeNotificationSource source;
    late NotificationsFeature phoneFeature;
    late NotificationsFeature laptopFeature;
    late FerretEngine phone;
    late FerretEngine laptop;
    late NotificationsFeatureUi laptopUi;
    late NotificationsFeatureUi phoneUi;
    late FeatureContext laptopContext;
    late FeatureContext phoneContext;
    final engines = <FerretEngine>[];

    Future<FerretEngine> startEngine(
      String name,
      proto.Platform platform,
      NotificationsFeature feature,
      MemorySettingsStore settings,
    ) async {
      final engine = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: settings,
        device: LocalDevice(
          name: name,
          platform: platform,
          formFactor: .FORM_FACTOR_LAPTOP,
        ),
        features: [feature],
        discovery: bus.join(),
        port: 0,
      );
      await engine.start();
      engines.add(engine);
      return engine;
    }

    Future<void> connect({bool enabled = true}) async {
      bus = Bus();
      source = FakeNotificationSource();
      phoneFeature = NotificationsFeature(source: source);
      laptopFeature = NotificationsFeature();
      phone = await startEngine(
        'Pixel 9',
        .PLATFORM_ANDROID,
        phoneFeature,
        MemorySettingsStore({
          MirrorPreferences.enabledKey: enabled,
          MirrorPreferences.allowedAppsKey: [signal, game],
        }),
      );
      laptop = await startEngine(
        'Laptop',
        .PLATFORM_LINUX,
        laptopFeature,
        MemorySettingsStore(),
      );

      final handle = await laptop.createPairingOffer();
      final offer = PairingCodes.parseOffer(handle.qrText);
      if (offer == null) {
        fail('The offer did not parse');
      }

      offer
        ..hosts.clear()
        ..hosts.add('127.0.0.1');
      expect(await phone.pairWithOffer(offer), isA<Paired>());
      await until(
        () => laptopFeature.senderSettings.containsKey(phone.identity.deviceId),
      );

      laptopUi = NotificationsFeatureUi.withFeature(laptopFeature);
      phoneUi = NotificationsFeatureUi.withFeature(
        phoneFeature,
        access: source,
      );
      laptopContext = FeatureContext(
        engine: laptop,
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: FakeNotifier(),
      );
      phoneContext = FeatureContext(
        engine: phone,
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: FakeNotifier(),
      );
      await laptopUi.onAppStarted(laptopContext);
      await phoneUi.onAppStarted(phoneContext);
      await pumpEventQueue();
    }

    Future<void> stop() async {
      laptopUi.dispose();
      phoneUi.dispose();
      for (final engine in engines) {
        await engine.stop();
      }

      engines.clear();
    }

    Future<BuildContext> pumpContext(WidgetTester tester) async {
      await tester.pumpWidget(testApp(const SizedBox()));
      await tester.pumpAndSettle();
      return tester.element(find.byType(ListView));
    }

    String phoneId() => phone.identity.deviceId;

    testWidgets('the computer row says how many apps the phone mirrors', (
      tester,
    ) async {
      await tester.runAsync(connect);
      addTearDown(() => tester.runAsync(stop));
      final context = await pumpContext(tester);

      final part = laptopUi.settingsSections(context, laptopContext).single;

      expect(part.group, SettingsGroup.phone);
      expect(part.isOn, isTrue);
      expect(part.summary, '2 apps');
      expect(part.needsAttention, isFalse);
    });

    testWidgets('a phone that never turned it on reads Off, with no warning', (
      tester,
    ) async {
      await tester.runAsync(() => connect(enabled: false));
      addTearDown(() => tester.runAsync(stop));
      final context = await pumpContext(tester);

      final part = laptopUi.settingsSections(context, laptopContext).single;
      final health = laptopUi.healthFor(laptopContext, laptop.devices.single);

      expect(part.isOn, isFalse);
      expect(part.needsAttention, isFalse);
      expect(health?.state, FeatureHealthState.off);
      expect(health?.help, contains('On Pixel 9: Ferret → Do more'));
      expect(
        laptopUi.deviceActions(context, laptopContext, laptop.devices.single),
        isEmpty,
      );
    });

    testWidgets('lost access on the phone needs attention on both sides', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await connect();
        source.accessGranted = false;
        await laptopFeature.fetchSettings(phoneId());
      });
      addTearDown(() => tester.runAsync(stop));
      final context = await pumpContext(tester);

      final part = laptopUi.settingsSections(context, laptopContext).single;
      final health = laptopUi.healthFor(laptopContext, laptop.devices.single);

      expect(part.summary, 'Needs access on Pixel 9');
      expect(part.needsAttention, isTrue);
      expect(health?.state, FeatureHealthState.needsAttention);
      expect(health?.help, 'On Pixel 9: open Ferret and tap Fix.');
      expect(health?.onFix, isNull);
    });

    testWidgets('the phone answers for the computer, and fixes lost access', (
      tester,
    ) async {
      await tester.runAsync(connect);
      addTearDown(() => tester.runAsync(stop));

      final working = phoneUi.healthFor(phoneContext, phone.devices.single);
      expect(working?.state, FeatureHealthState.ok);
      expect(working?.reason, '2 apps');

      source.accessGranted = false;
      phoneUi.dispose();
      phoneUi = NotificationsFeatureUi.withFeature(
        phoneFeature,
        access: source,
      );
      await tester.runAsync(() async {
        await phoneUi.onAppStarted(phoneContext);
        await pumpEventQueue();
      });

      final lost = phoneUi.healthFor(phoneContext, phone.devices.single);
      expect(lost?.state, FeatureHealthState.needsAttention);
      lost?.onFix?.call();
      await tester.runAsync(pumpEventQueue);
      expect(source.openedAccessSettings, 1);
    });

    testWidgets('the phone page holds its switches and its app picker', (
      tester,
    ) async {
      await tester.runAsync(connect);
      addTearDown(() => tester.runAsync(stop));
      final context = await pumpContext(tester);
      final device = laptop.devices.single;
      var changes = 0;
      laptopUi.uiChanges?.addListener(() => changes++);

      final permissions = laptopUi.devicePermissions(
        context,
        laptopContext,
        device,
      );
      expect(permissions.map((permission) => permission.label), [
        'Show its notifications here',
        "Hold them back while it's in use",
      ]);
      expect(permissions.first.value, isTrue);
      expect(permissions.last.value, isTrue);
      expect(
        laptopUi
            .deviceActions(context, laptopContext, device)
            .map((action) => action.label),
        ['Pick notification apps'],
      );

      await tester.runAsync(() async {
        permissions.last.onChanged(false);
        await until(
          () =>
              laptopFeature.senderSettings[phoneId()]?.skipWhileUsing == false,
        );
      });
      expect(phoneFeature.preferences.skipWhileUsing, isFalse);
      expect(changes, greaterThan(0));

      changes = 0;
      await tester.runAsync(() async {
        permissions.first.onChanged(false);
        await until(() => changes > 0);
      });

      final hidden = laptopUi.devicePermissions(context, laptopContext, device);
      final health = laptopUi.healthFor(laptopContext, device);
      final part = laptopUi.settingsSections(context, laptopContext).single;
      expect(hidden.single.value, isFalse);
      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Turned off here');
      expect(part.isOn, isFalse);
      expect(laptopUi.deviceActions(context, laptopContext, device), isEmpty);

      final received = <MirrorEvent>[];
      laptopFeature.mirrorEvents.listen(received.add);
      await tester.runAsync(() async {
        source.post(phoneNotification());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      expect(received.whereType<MirrorPosted>(), isEmpty);
    });

    testWidgets('no part on a computer with no Android phone paired', (
      tester,
    ) async {
      final feature = NotificationsFeature();
      bus = Bus();
      await tester.runAsync(() async {
        laptop = await startEngine(
          'Laptop',
          .PLATFORM_LINUX,
          feature,
          MemorySettingsStore(),
        );
      });
      final ui = NotificationsFeatureUi.withFeature(feature);
      addTearDown(
        () => tester.runAsync(() async {
          ui.dispose();
          await laptop.stop();
          engines.clear();
        }),
      );
      final context = await pumpContext(tester);

      expect(
        ui.settingsSections(
          context,
          FeatureContext(
            engine: laptop,
            navigatorKey: GlobalKey<NavigatorState>(),
            notifier: FakeNotifier(),
          ),
        ),
        isEmpty,
      );
    });
  });
}
