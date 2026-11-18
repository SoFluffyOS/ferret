import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:find/find.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/find.dart';

import 'helpers/fakes.dart';

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
}
