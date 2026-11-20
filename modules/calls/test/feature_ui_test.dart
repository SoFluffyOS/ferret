import 'package:calls/calls.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/calls.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

class _FakeEngine implements FerretEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final context = FeatureContext(
    engine: _FakeEngine(),
    navigatorKey: GlobalKey<NavigatorState>(),
    notifier: FakeNotifier(),
  );

  group('on a computer', () {
    late FakeSession pixel;
    late CallsFeature feature;
    late CallsFeatureUi ui;
    late int changes;

    CallUpdate update(CallState state) => CallUpdate(
      call: Call(
        id: 'call-1',
        direction: .CALL_DIRECTION_INCOMING,
        state: state,
      ),
    );

    setUp(() async {
      pixel = FakeSession('phone', flags: [CallsFeature.phoneFlag]);
      feature = CallsFeature();
      await feature.start(FakeHost()..sessions = [pixel]);
      ui = CallsFeatureUi.withFeature(feature);
      changes = 0;
      ui.uiChanges.addListener(() => changes++);
    });

    tearDown(() async {
      await ui.dispose();
      await feature.stop();
    });

    test('never has a card: a call is a line in Activity', () async {
      final idle = ui.hasHomeCard(context);

      await feature.onEnvelope(pixel, envelopeOf(update(.CALL_STATE_RINGING)));
      await settle();
      final ringing = ui.hasHomeCard(context);

      await feature.onEnvelope(pixel, envelopeOf(update(.CALL_STATE_ENDED)));
      await settle();

      expect(idle, isFalse);
      expect(ringing, isFalse);
      expect(changes, greaterThanOrEqualTo(2));
    });
  });

  group('activity', () {
    late CallsFeature feature;
    late CallsFeatureUi ui;

    Future<List<ActivityItem>> activityOf(
      WidgetTester tester, {
      required bool isPhone,
    }) async {
      await tester.runAsync(() async {
        final session = FakeSession('phone', flags: [CallsFeature.phoneFlag]);
        feature = switch (isPhone) {
          true => CallsFeature(phone: FakePhone()),
          false => CallsFeature(),
        };
        await feature.start(FakeHost()..sessions = [session]);
        ui = CallsFeatureUi.withFeature(feature);
        await feature.onEnvelope(
          session,
          envelopeOf(
            CallUpdate(
              call: Call(
                id: 'call-1',
                contactName: 'Alex',
                direction: .CALL_DIRECTION_INCOMING,
                state: .CALL_STATE_RINGING,
              ),
            ),
          ),
        );
        await settle();
      });
      addTearDown(
        () => tester.runAsync(() async {
          await ui.dispose();
          await feature.stop();
        }),
      );
      await tester.pumpWidget(testApp(const SizedBox()));
      await tester.pumpAndSettle();

      return ui.activity(tester.element(find.byType(ListView)), context);
    }

    testWidgets('a computer pins the call a phone reports', (tester) async {
      final lines = await activityOf(tester, isPhone: false);

      expect(lines.single.pinned, isTrue);
      expect(lines.single.title, startsWith('Alex is calling '));
      expect(lines.single.actions, hasLength(3));
    });

    testWidgets('the phone has no lines', (tester) async {
      expect(await activityOf(tester, isPhone: true), isEmpty);
    });
  });

  group('on the phone', () {
    late FakePhone phone;
    late FakeSession laptop;
    late FakeHost host;
    late CallsFeature feature;
    late CallsFeatureUi ui;

    Future<void> start({required bool enabled}) async {
      host = FakeHost(settings: {CallsSettings.enabledKey: enabled})
        ..sessions = [laptop];
      feature = CallsFeature(phone: phone);
      await feature.start(host);
      await settle();
      ui = CallsFeatureUi.withFeature(feature);
    }

    setUp(() {
      phone = FakePhone();
      laptop = FakeSession('laptop');
    });

    tearDown(() async {
      await ui.dispose();
      await feature.stop();
    });

    test('has no card while off or once calls work', () async {
      await start(enabled: false);
      final whileOff = ui.hasHomeCard(context);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      await host.settings.set(CallsSettings.enabledKey, true);
      await settle();

      expect(whileOff, isFalse);
      expect(ui.hasHomeCard(context), isFalse);
      expect(changes, greaterThan(0));
    });

    test('shows the card when the phone permission is missing', () async {
      phone.granted = noPermissions();
      await start(enabled: true);

      expect(ui.hasHomeCard(context), isTrue);
    });

    test('a failed push to a computer refreshes the health chips', () async {
      await start(enabled: true);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);
      laptop.failSends = true;

      phone.ring();
      await settle();

      expect(feature.pushFailedTo('laptop'), isTrue);
      expect(changes, greaterThan(0));
    });
  });

  group('the offer', () {
    late FakeHost host;
    late CallsFeature feature;

    Future<FeatureOffer?> offerOn(
      WidgetTester tester, {
      required bool enabled,
      bool isPhone = true,
      bool telephony = true,
    }) async {
      await tester.runAsync(() async {
        host = FakeHost(settings: {CallsSettings.enabledKey: enabled});
        feature = switch (isPhone) {
          true => CallsFeature(phone: FakePhone()..telephony = telephony),
          false => CallsFeature(),
        };
        await feature.start(host);
        await settle();
      });
      addTearDown(() => tester.runAsync(feature.stop));
      await tester.pumpWidget(testApp(const SizedBox()));
      await tester.pumpAndSettle();

      final ui = CallsFeatureUi.withFeature(feature);
      return ui.offerFor(tester.element(find.byType(ListView)), context);
    }

    testWidgets('a phone with calls off offers them', (tester) async {
      final offer = await offerOn(tester, enabled: false);

      expect(offer?.title, 'Calls');
      expect(
        offer?.description,
        "See who's calling and answer from your computer.",
      );
      expect(offer?.actionLabel, 'Set up');
    });

    testWidgets('no offer once calls are on', (tester) async {
      expect(await offerOn(tester, enabled: true), isNull);
    });

    testWidgets('no offer on a computer', (tester) async {
      expect(await offerOn(tester, enabled: false, isPhone: false), isNull);
    });

    testWidgets('no offer on a tablet without calls', (tester) async {
      expect(await offerOn(tester, enabled: false, telephony: false), isNull);
    });
  });
}
