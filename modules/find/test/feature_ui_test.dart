import 'dart:async';
import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/find.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/find.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

class _FakeEngine implements FerretEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QuietNotifier implements LocalNotifier {
  @override
  Future<void> show(LocalNotice notice) async {}

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}

void main() {
  testWidgets('rings bring the app to the front once, and show the card', (
    tester,
  ) async {
    final host = await tester.runAsync(FakeHost.create);
    if (host == null) {
      fail('The host should start');
    }

    final pixel = FakeSession('pixel', name: 'Pixel');
    host.sessions = [pixel];
    final ui = FindFeatureUi(
      feature: FindFeature(platform: FakeFindPlatform.new),
    );
    await ui.feature.start(host);
    var reveals = 0;
    var changes = 0;
    final context = FeatureContext(
      engine: _FakeEngine(),
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: _QuietNotifier(),
      onReveal: () async => reveals++,
    );
    await ui.onAppStarted(context);
    ui.uiChanges.addListener(() => changes++);
    final idle = ui.hasHomeCard(context);

    await ui.feature.onEnvelope(pixel, envelopeOf(RingRequest()));
    await tester.pump();
    final ringing = ui.hasHomeCard(context);
    final revealsWhileRinging = reveals;
    await ui.feature.onEnvelope(pixel, envelopeOf(RingRequest()));
    await tester.pump();

    expect(idle, isFalse);
    expect(ringing, isTrue);
    expect(revealsWhileRinging, 1);
    expect(reveals, 1);
    expect(changes, greaterThan(0));

    await ui.feature.foundIt();
    await tester.pump();
    expect(ui.hasHomeCard(context), isFalse);

    await tester.runAsync(ui.dispose);
    await tester.runAsync(ui.feature.stop);
  });

  group('settings part', () {
    Future<FeatureSettings> partFor(
      WidgetTester tester,
      RingAbilities abilities, {
      Map<String, Object?>? settings,
      void Function(FakeFindPlatform platform)? afterStart,
    }) async {
      final host = await tester.runAsync(
        () => FakeHost.create(settings: settings),
      );
      if (host == null) {
        fail('The host should start');
      }

      final platform = FakeFindPlatform(abilitiesNow: abilities);
      final ui = FindFeatureUi(feature: FindFeature(platform: () => platform));
      await ui.feature.start(host);
      if (afterStart != null) {
        afterStart(platform);
        await ui.feature.refreshAbilities();
      }

      late List<FeatureSettings> sections;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              sections = ui.settingsSections(context, _NoContext());
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.runAsync(ui.feature.stop);

      return sections.single;
    }

    const android = RingAbilities(
      controlsVolume: true,
      needsDndAccess: true,
      dndAccessGranted: true,
    );
    const androidWithoutAccess = RingAbilities(
      controlsVolume: true,
      needsDndAccess: true,
    );

    testWidgets('sits under Control and says how this device rings', (
      tester,
    ) async {
      final part = await partFor(tester, android);

      expect(part.group, SettingsGroup.control);
      expect(part.title, 'Find');
      expect(part.summary, 'Rings on silent');
      expect(part.isOn, isNull);
      expect(part.needsAttention, isFalse);
    });

    testWidgets('access that was never given is not a problem', (tester) async {
      final part = await partFor(tester, androidWithoutAccess);

      expect(part.summary, 'Quiet in Do Not Disturb');
      expect(part.needsAttention, isFalse);
    });

    testWidgets('access that went away needs attention', (tester) async {
      final part = await partFor(
        tester,
        android,
        afterStart: (platform) => platform.abilitiesNow = androidWithoutAccess,
      );

      expect(part.summary, 'Quiet in Do Not Disturb');
      expect(part.needsAttention, isTrue);
    });

    testWidgets('ringing on silent turned off is a choice, not a problem', (
      tester,
    ) async {
      final part = await partFor(
        tester,
        androidWithoutAccess,
        settings: {
          FindSettings.ringOnSilentKey: false,
          FindSettings.hadDndAccessKey: true,
        },
      );

      expect(part.summary, 'Quiet on silent');
      expect(part.needsAttention, isFalse);
    });

    testWidgets('a computer rings at the current volume', (tester) async {
      final part = await partFor(tester, const RingAbilities());

      expect(part.summary, 'Rings at the current volume');
    });
  });

  group('health on a device page', () {
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

    Future<FindFeatureUi> startUi(FakeSession session) async {
      final host = await FakeHost.create();
      host.sessions = [session];
      final ui = FindFeatureUi(
        feature: FindFeature(
          platform: FakeFindPlatform.new,
          requestTimeout: const Duration(milliseconds: 10),
        ),
      );
      await ui.feature.start(host);
      return ui;
    }

    test('says it is checking until the device answered', () async {
      final pixel = FakeSession('pixel');
      final ui = await startUi(pixel);

      final health = ui.healthFor(_NoContext(), statusOf(pixel));

      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Checking Pixel…');
      await ui.feature.stop();
    });

    test(
      'a missing permission says where to allow it on that device',
      () async {
        final pixel = FakeSession(
          'pixel',
          answer: (_) => RingInfo(needsPermission: true),
        );
        final ui = await startUi(pixel);
        ui.feature.onSessionOpened(pixel);
        await settle();

        final health = ui.healthFor(_NoContext(), statusOf(pixel));

        expect(health?.state, FeatureHealthState.needsAttention);
        expect(health?.help, startsWith('On Pixel: open Ferret → Settings → '));
        expect(health?.help, contains('Control'));
        expect(health?.onFix, isNull);
        await ui.feature.stop();
      },
    );

    test('a device that did not answer can be asked again', () async {
      final pixel = FakeSession('pixel');
      final ui = await startUi(pixel);
      ui.feature.onSessionOpened(pixel);
      await settle();
      final failing = ui.healthFor(_NoContext(), statusOf(pixel));

      pixel.answer = (_) => RingInfo(ringsWhenSilent: true);
      failing?.onFix?.call();
      await settle();
      final fixed = ui.healthFor(_NoContext(), statusOf(pixel));

      expect(failing?.state, FeatureHealthState.failing);
      expect(failing?.onFix, isNotNull);
      expect(fixed?.state, FeatureHealthState.ok);
      expect(fixed?.reason, 'Rings, even on silent');
      await ui.feature.stop();
    });

    test('an old Ferret is off, with the step for that device', () async {
      final old = FakeSession('old', name: 'Old Pixel', supportsFind: false);
      final ui = await startUi(old);

      final health = ui.healthFor(_NoContext(), statusOf(old));

      expect(health?.state, FeatureHealthState.off);
      expect(health?.help, 'On Old Pixel: update Ferret.');
      await ui.feature.stop();
    });
  });
}

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
