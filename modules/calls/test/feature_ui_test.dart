import 'package:calls/calls.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/calls.dart';

import 'support/fakes.dart';

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

    test('has a card only while a call rings or goes on', () async {
      final idle = ui.hasHomeCard(context);

      await feature.onEnvelope(pixel, envelopeOf(update(.CALL_STATE_RINGING)));
      await settle();
      final ringing = ui.hasHomeCard(context);

      await feature.onEnvelope(pixel, envelopeOf(update(.CALL_STATE_ENDED)));
      await settle();

      expect(idle, isFalse);
      expect(ringing, isTrue);
      expect(ui.hasHomeCard(context), isFalse);
      expect(changes, greaterThanOrEqualTo(2));
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

    test('has a card only while calls need setting up', () async {
      await start(enabled: false);
      final whileOff = ui.hasHomeCard(context);

      await host.settings.set(CallsSettings.enabledKey, true);
      await settle();

      expect(whileOff, isTrue);
      expect(ui.hasHomeCard(context), isFalse);
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
}
