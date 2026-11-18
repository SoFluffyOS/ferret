import 'dart:typed_data';

import 'package:calls/calls.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/calls.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

class _FakeEngine implements FerretEngine {
  _FakeEngine(this.trustStore);

  @override
  final TrustStore trustStore;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final pixel = TrustedDevice(
    id: 'phone',
    name: 'Pixel 9',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026),
  );
  final macBook = TrustedDevice(
    id: 'laptop',
    name: 'MacBook',
    platform: .PLATFORM_MACOS,
    formFactor: .FORM_FACTOR_LAPTOP,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026),
  );

  late FakeHost host;
  late CallsFeature feature;
  late CallsFeatureUi ui;
  late FeatureContext context;

  Future<void> start(
    WidgetTester tester,
    CallsFeature Function() create, {
    Map<String, Object?> settings = const {},
    List<FakeSession> sessions = const [],
    List<TrustedDevice> paired = const [],
  }) async {
    await tester.runAsync(() async {
      final trustStore = await TrustStore.open(MemorySecretStore());
      for (final device in paired) {
        await trustStore.save(device);
      }

      host = FakeHost(settings: {...settings})..sessions = [...sessions];
      feature = create();
      await feature.start(host);
      await settle();
      context = FeatureContext(
        engine: _FakeEngine(trustStore),
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: FakeNotifier(),
      );
    });
    ui = CallsFeatureUi.withFeature(feature);
    addTearDown(
      () => tester.runAsync(() async {
        await ui.dispose();
        await feature.stop();
      }),
    );
    await tester.pumpWidget(testApp(const SizedBox()));
    await tester.pumpAndSettle();
  }

  List<FeatureSettings> sections(WidgetTester tester) =>
      ui.settingsSections(tester.element(find.byType(ListView)), context);

  group('on a computer', () {
    late FakeSession toPhone;

    Future<void> startComputer(
      WidgetTester tester, {
      bool paired = true,
      Map<String, Object?> settings = const {},
    }) async {
      toPhone = FakeSession(
        'phone',
        name: 'Pixel 9',
        flags: [CallsFeature.phoneFlag],
      );
      await start(
        tester,
        CallsFeature.new,
        settings: settings,
        sessions: [toPhone],
        paired: [if (paired) pixel],
      );
    }

    Future<void> phoneSays(WidgetTester tester, CallsStatus status) =>
        tester.runAsync(() async {
          await feature.onEnvelope(toPhone, envelopeOf(status));
          await settle();
        });

    FeatureHealth? health() =>
        ui.healthFor(context, DeviceStatus(pixel, toPhone));

    testWidgets('no part until an Android phone is paired', (tester) async {
      await startComputer(tester, paired: false);

      expect(sections(tester), isEmpty);
    });

    testWidgets('off and quiet before the phone ever shared', (tester) async {
      await startComputer(tester);

      final part = sections(tester).single;

      expect(part.group, SettingsGroup.phone);
      expect(part.title, 'Calls');
      expect(part.isOn, isFalse);
      expect(part.needsAttention, isFalse);
      expect(health()?.state, FeatureHealthState.off);
      expect(health()?.reason, 'Checking…');
    });

    testWidgets('on once the phone shares, and still on while it is away', (
      tester,
    ) async {
      await startComputer(tester);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      await phoneSays(
        tester,
        CallsStatus(enabled: true, canSeeCalls: true, canAnswer: true),
      );

      expect(changes, greaterThan(0));
      expect(sections(tester).single.isOn, isTrue);
      expect(health()?.state, FeatureHealthState.ok);

      await tester.runAsync(() async {
        host.sessions = [];
        feature.onSessionClosed(toPhone);
        await settle();
      });

      expect(sections(tester).single.isOn, isTrue);
      expect(sections(tester).single.needsAttention, isFalse);
    });

    testWidgets('off on the phone says where to turn it on', (tester) async {
      await startComputer(tester);
      await phoneSays(tester, CallsStatus(enabled: false));

      expect(sections(tester).single.isOn, isFalse);
      expect(health()?.state, FeatureHealthState.off);
      expect(health()?.help, 'On Pixel 9: Ferret → Do more → Calls.');
      expect(health()?.onFix, isNull);
    });

    testWidgets('lost access on the phone needs attention', (tester) async {
      await startComputer(tester);
      await phoneSays(tester, CallsStatus(enabled: true, canSeeCalls: false));

      final part = sections(tester).single;

      expect(part.isOn, isTrue);
      expect(part.summary, 'Needs access on Pixel 9');
      expect(part.needsAttention, isTrue);
      expect(health()?.state, FeatureHealthState.needsAttention);
      expect(health()?.help, 'On Pixel 9: open Ferret and tap Fix.');
    });

    testWidgets('a phone that stopped answering warns only if it shared', (
      tester,
    ) async {
      await startComputer(tester);
      await tester.runAsync(() async {
        await feature.refreshStatus('phone');
        await settle();
      });

      expect(health()?.state, FeatureHealthState.failing);
      expect(health()?.onFix, isNotNull);
      expect(sections(tester).single.needsAttention, isFalse);

      await phoneSays(
        tester,
        CallsStatus(enabled: true, canSeeCalls: true, canAnswer: true),
      );
      await tester.runAsync(() async {
        await feature.refreshStatus('phone');
        await settle();
      });

      final part = sections(tester).single;
      expect(part.summary, "Pixel 9 didn't answer");
      expect(part.needsAttention, isTrue);
    });
  });

  group('on the phone', () {
    late FakePhone phone;
    late FakeSession toLaptop;

    Future<void> startPhone(WidgetTester tester, {required bool enabled}) {
      toLaptop = FakeSession('laptop');
      return start(
        tester,
        () => CallsFeature(phone: phone),
        settings: {CallsSettings.enabledKey: enabled},
        sessions: [toLaptop],
        paired: [macBook],
      );
    }

    FeatureHealth? health() =>
        ui.healthFor(context, DeviceStatus(macBook, toLaptop));

    setUp(() => phone = FakePhone());

    testWidgets('off until it is set up, and says where to turn it on', (
      tester,
    ) async {
      await startPhone(tester, enabled: false);

      final part = sections(tester).single;

      expect(part.group, SettingsGroup.phone);
      expect(part.isOn, isFalse);
      expect(part.needsAttention, isFalse);
      expect(health()?.state, FeatureHealthState.off);
      expect(
        health()?.help,
        'On this phone: Settings → To your computer → Calls.',
      );
    });

    testWidgets('on without the phone permission needs attention, with a fix', (
      tester,
    ) async {
      phone.granted = noPermissions();
      await startPhone(tester, enabled: true);

      final part = sections(tester).single;

      expect(part.isOn, isTrue);
      expect(part.summary, 'Needs access');
      expect(part.needsAttention, isTrue);
      expect(health()?.state, FeatureHealthState.needsAttention);
      expect(health()?.onFix, isNotNull);
    });

    testWidgets('working, the computer gets a check', (tester) async {
      await startPhone(tester, enabled: true);

      expect(sections(tester).single.isOn, isTrue);
      expect(sections(tester).single.needsAttention, isFalse);
      expect(health()?.state, FeatureHealthState.ok);
    });

    testWidgets('a call that did not reach the computer says what to do', (
      tester,
    ) async {
      await startPhone(tester, enabled: true);
      await tester.runAsync(() async {
        toLaptop.failSends = true;
        phone.ring();
        await settle();
      });

      expect(health()?.state, FeatureHealthState.failing);
      expect(
        health()?.help,
        'On MacBook: open Ferret. The next call shows there.',
      );
    });
  });
}
