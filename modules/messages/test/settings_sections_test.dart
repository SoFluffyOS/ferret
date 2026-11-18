import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';

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
    id: PhoneAndComputer.phoneId,
    name: 'Pixel',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026),
  );
  final macBook = TrustedDevice(
    id: PhoneAndComputer.computerId,
    name: 'MacBook',
    platform: .PLATFORM_MACOS,
    formFactor: .FORM_FACTOR_LAPTOP,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026),
  );

  late FakeSmsSource source;
  late PhoneAndComputer devices;
  late TrustStore trustStore;
  late FeatureContext context;

  Future<void> start(
    WidgetTester tester, {
    bool enabled = true,
    bool paired = true,
    FakeSmsSource? sms,
  }) async {
    await tester.runAsync(() async {
      source = sms ?? FakeSmsSource();
      devices = await PhoneAndComputer.start(source: source, enabled: enabled);
      trustStore = await TrustStore.open(MemorySecretStore());
      if (paired) {
        await trustStore.save(pixel);
      }
    });
    context = FeatureContext(
      engine: _FakeEngine(trustStore),
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: FakeNotifier(),
    );
    addTearDown(() => tester.runAsync(devices.stop));
    await tester.pumpWidget(testApp(const SizedBox()));
    await tester.pumpAndSettle();
  }

  List<FeatureSettings> sections(WidgetTester tester, MessagesFeatureUi ui) =>
      ui.settingsSections(tester.element(find.byType(ListView)), context);

  group('on a computer', () {
    late MessagesFeatureUi ui;

    Future<void> startComputer(
      WidgetTester tester, {
      bool enabled = true,
      bool paired = true,
      FakeSmsSource? sms,
      bool connect = true,
    }) async {
      await start(tester, enabled: enabled, paired: paired, sms: sms);
      ui = MessagesFeatureUi.withFeature(devices.computer);
      if (connect) {
        await tester.runAsync(devices.connect);
      }
    }

    FeatureHealth? health() =>
        ui.healthFor(context, DeviceStatus(pixel, devices.toPhone));

    testWidgets('no part until an Android phone is paired', (tester) async {
      await startComputer(tester, paired: false, connect: false);

      expect(sections(tester, ui), isEmpty);
    });

    testWidgets('sits under From your phone, on once the phone shares', (
      tester,
    ) async {
      await startComputer(tester);

      final part = sections(tester, ui).single;

      expect(part.group, SettingsGroup.phone);
      expect(part.title, 'Messages');
      expect(part.isOn, isTrue);
      expect(part.needsAttention, isFalse);
    });

    testWidgets('a phone that never turned it on reads off, with the way', (
      tester,
    ) async {
      await startComputer(tester, enabled: false);

      final part = sections(tester, ui).single;

      expect(part.isOn, isFalse);
      expect(part.needsAttention, isFalse);
      expect(health()?.state, FeatureHealthState.off);
      expect(health()?.help, 'On Pixel: Ferret → Do more → Messages.');
      expect(health()?.onFix, isNull);
    });

    testWidgets('lost SMS access needs attention and says what to do', (
      tester,
    ) async {
      await startComputer(tester, sms: FakeSmsSource(canRead: false));

      final part = sections(tester, ui).single;

      expect(part.isOn, isTrue);
      expect(part.summary, 'Needs access on Pixel');
      expect(part.needsAttention, isTrue);
      expect(health()?.state, FeatureHealthState.needsAttention);
      expect(health()?.help, 'On Pixel: open Ferret and allow SMS.');
    });

    testWidgets('a phone that stopped answering can be asked again', (
      tester,
    ) async {
      await startComputer(tester);
      await tester.runAsync(() async {
        devices.toPhone?.unresponsive = true;
        await devices.library.loadOlderConversations(PhoneAndComputer.phoneId);
        await devices.library.loadNewestMessages(PhoneAndComputer.phoneId, 1);
      });

      final part = sections(tester, ui).single;
      expect(part.summary, "Pixel didn't answer");
      expect(part.needsAttention, isTrue);
      expect(health()?.state, FeatureHealthState.failing);

      await tester.runAsync(() async {
        devices.toPhone?.unresponsive = false;
        health()?.onFix?.call();
        await settle();
      });

      expect(health()?.state, FeatureHealthState.ok);
      expect(sections(tester, ui).single.needsAttention, isFalse);
    });

    testWidgets('the row changes when the phone turns Messages off', (
      tester,
    ) async {
      await startComputer(tester);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      await tester.runAsync(() async {
        await devices.phone.settings.setEnabled(false);
        await settle();
      });

      expect(changes, greaterThan(0));
      expect(sections(tester, ui).single.isOn, isFalse);
    });
  });

  group('on the phone', () {
    late MessagesFeatureUi ui;

    Future<void> startPhone(
      WidgetTester tester, {
      bool enabled = true,
      FakeSmsSource? sms,
    }) async {
      await start(tester, enabled: enabled, sms: sms);
      ui = MessagesFeatureUi.withFeature(devices.phone);
      await tester.runAsync(devices.connect);
    }

    FeatureHealth? health() =>
        ui.healthFor(context, DeviceStatus(macBook, devices.toComputer));

    testWidgets('off until it is set up, and says where to turn it on', (
      tester,
    ) async {
      await startPhone(tester, enabled: false);

      final part = sections(tester, ui).single;

      expect(part.group, SettingsGroup.phone);
      expect(part.isOn, isFalse);
      expect(part.needsAttention, isFalse);
      expect(health()?.state, FeatureHealthState.off);
      expect(health()?.reason, 'Off on this phone');
      expect(
        health()?.help,
        'On this phone: Settings → To your computer → Messages.',
      );
    });

    testWidgets('on without SMS access needs attention, with a fix', (
      tester,
    ) async {
      await startPhone(tester, sms: FakeSmsSource(canRead: false));

      final part = sections(tester, ui).single;

      expect(part.isOn, isTrue);
      expect(part.summary, 'Needs access');
      expect(part.needsAttention, isTrue);
      expect(health()?.state, FeatureHealthState.needsAttention);
      expect(health()?.onFix, isNotNull);
    });

    testWidgets('working, the computer gets a check', (tester) async {
      await startPhone(tester);

      expect(sections(tester, ui).single.isOn, isTrue);
      expect(health()?.state, FeatureHealthState.ok);
      expect(health()?.reason, 'Texts and replies');
    });

    testWidgets('a device that cannot text has no part and no line', (
      tester,
    ) async {
      await startPhone(tester, sms: FakeSmsSource(hasTelephony: false));

      expect(sections(tester, ui), isEmpty);
      expect(health(), isNull);
    });
  });
}
