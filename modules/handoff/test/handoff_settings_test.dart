import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/handoff.dart';
import 'package:protocol/protocol.dart';

import 'support/browser_fakes.dart';
import 'support/fakes.dart';

/// A connected device that answers a sent link, or doesn't.
class _Session implements Session {
  _Session({this.hasContinue = true});

  final bool hasContinue;
  bool answers = true;
  ContinueOutcome outcome = .CONTINUE_OUTCOME_OPENED;

  @override
  String get remoteDeviceId => 'pixel-id';

  @override
  DeviceInfo? get remoteDevice => DeviceInfo(id: 'pixel-id', name: 'Pixel 9');

  @override
  bool supports(String featureId) => hasContinue;

  @override
  Future<T> call<T extends GeneratedMessage>(
    String feature,
    GeneratedMessage message,
    T Function() create, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!answers) {
      throw StateError('no answer');
    }

    return ContinueResult(outcome: outcome) as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A server whose ports can all be taken later on.
class _FlakyServer extends BrowserBridgeServer {
  @override
  int? port = BrowserBridgeServer.firstPort;

  @override
  Future<int?> start(void Function(BrowserChannel channel) onChannel) async =>
      port;

  @override
  Future<void> stop() async {}
}

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final featureContext = _NoContext();
  late FakeHost host;

  Future<HandoffFeatureUi> start(
    WidgetTester tester, {
    bool browserBridge = true,
    BrowserBridgeServer? server,
    Map<String, Object?>? settings,
  }) async {
    final ui = HandoffFeatureUi(
      opener: FakeOpener(),
      handoff: FerretHandoff(
        api: FakeHandoffApi(),
        isAndroid: false,
        isMacOS: false,
      ),
      browserBridge: browserBridge,
      browserServer: server ?? IdleServer(),
    );
    await tester.runAsync(() async {
      host = await FakeHost.create(settings);
      await ui.feature.start(host);
      await ui.browser.start();
    });
    addTearDown(() async {
      ui.dispose();
      await ui.feature.stop();
    });
    return ui;
  }

  Future<List<FeatureSettings>> sections(
    WidgetTester tester,
    HandoffFeatureUi ui,
  ) async {
    late List<FeatureSettings> parts;
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) {
            parts = ui.settingsSections(context, featureContext);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return parts;
  }

  Future<void> pairBrowser(WidgetTester tester, HandoffFeatureUi ui) =>
      tester.runAsync(() async {
        final channel = FakeChannel();
        ui.browser.attach(channel);
        channel
          ..say({'type': 'hello', 'v': 1, 'browser': 'Firefox'})
          ..say({'type': 'pair', 'code': '123456'});
        await pumpEventQueue();
        await ui.browser.answerPair(
          ui.browser.pairRequests.single.id,
          allow: true,
        );
        await pumpEventQueue();
      });

  DeviceStatus statusOf(Session? session) =>
      DeviceStatus(trustedDevice('pixel-id', 'Pixel 9'), session);

  group('the Settings parts', () {
    testWidgets('Continue sits with media, the extension with other apps', (
      tester,
    ) async {
      final ui = await start(tester);

      final [continuePart, browserPart] = await sections(tester, ui);

      expect(continuePart.group, SettingsGroup.continueAndMedia);
      expect(continuePart.title, 'Continue');
      expect(continuePart.summary, "Offers the page you're on");
      expect(continuePart.isOn, isTrue);
      expect(continuePart.needsAttention, isFalse);
      expect(browserPart.group, SettingsGroup.otherApps);
      expect(browserPart.title, 'Browser extension');
      expect(browserPart.summary, 'No browser yet');
      expect(browserPart.isOn, isFalse);
      expect(browserPart.needsAttention, isFalse);
    });

    testWidgets('a phone has no browser extension part', (tester) async {
      final ui = await start(tester, browserBridge: false);

      final parts = await sections(tester, ui);

      expect(parts.single.group, SettingsGroup.continueAndMedia);
    });

    testWidgets('suggestions off leaves only what you send', (tester) async {
      final ui = await start(tester);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      await tester.runAsync(() async {
        await ui.feature.setPassiveEnabled(false);
        await pumpEventQueue();
      });

      final parts = await sections(tester, ui);
      expect(changes, greaterThan(0));
      expect(parts.first.summary, 'Only what you send');
      expect(parts.first.isOn, isFalse);
    });

    testWidgets('a paired browser turns the extension part on, by name', (
      tester,
    ) async {
      final ui = await start(tester);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      await pairBrowser(tester, ui);

      final browserPart = (await sections(tester, ui)).last;
      expect(changes, greaterThan(0));
      expect(browserPart.isOn, isTrue);
      expect(browserPart.summary, 'Firefox');
      expect(browserPart.needsAttention, isFalse);
    });

    testWidgets('a connection that never started is not a problem yet', (
      tester,
    ) async {
      final ui = await start(tester, server: IdleServer(port: null));

      final browserPart = (await sections(tester, ui)).last;

      expect(browserPart.needsAttention, isFalse);
      expect(browserPart.isOn, isFalse);
    });

    testWidgets('a paired browser that lost its connection needs attention', (
      tester,
    ) async {
      final server = _FlakyServer();
      final ui = await start(tester, server: server);
      await pairBrowser(tester, ui);

      server.port = null;
      await tester.runAsync(ui.browser.refresh);

      expect((await sections(tester, ui)).last.needsAttention, isTrue);
    });

    testWidgets('the extension turned off says so', (tester) async {
      final ui = await start(
        tester,
        settings: {HandoffSettings.browserBridge: false},
      );

      final browserPart = (await sections(tester, ui)).last;

      expect(browserPart.summary, 'Off');
      expect(browserPart.isOn, isFalse);
    });
  });

  group('health with a device', () {
    testWidgets('nothing to say when it is not connected', (tester) async {
      final ui = await start(tester);

      expect(ui.healthFor(featureContext, statusOf(null)), isNull);
    });

    testWidgets('says what happens to the links it sends here', (
      tester,
    ) async {
      final ui = await start(tester);

      final health = ui.healthFor(featureContext, statusOf(_Session()));

      expect(health?.state, FeatureHealthState.ok);
      expect(health?.reason, 'Links from Pixel 9 open right away');

      await tester.runAsync(() => ui.feature.setOpensAutomatically(false));

      expect(
        ui.healthFor(featureContext, statusOf(_Session()))?.reason,
        'Links from Pixel 9 wait in a notification',
      );
    });

    testWidgets('a link that got no answer shows until one arrives', (
      tester,
    ) async {
      final ui = await start(tester);
      final session = _Session()..answers = false;
      host.connected['pixel-id'] = session;
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      await tester.runAsync(() async {
        await ui.feature.sendTo('pixel-id', webActivity('a'));
        await pumpEventQueue();
      });

      await tester.pump();

      final failing = ui.healthFor(featureContext, statusOf(session));
      expect(changes, greaterThan(0));
      expect(failing?.state, FeatureHealthState.failing);
      expect(failing?.reason, "Pixel 9 didn't get the last link you sent");
      expect(
        failing?.help,
        'On Pixel 9: open Ferret, then send the link again.',
      );

      session.answers = true;
      await tester.runAsync(
        () => ui.feature.sendTo('pixel-id', webActivity('b')),
      );

      expect(
        ui.healthFor(featureContext, statusOf(session))?.state,
        FeatureHealthState.ok,
      );
    });

    testWidgets('a link that arrived but could not open says so', (
      tester,
    ) async {
      final ui = await start(tester);
      final session = _Session()..outcome = .CONTINUE_OUTCOME_FAILED;
      host.connected['pixel-id'] = session;

      await tester.runAsync(
        () => ui.feature.sendTo('pixel-id', webActivity('a')),
      );

      final failing = ui.healthFor(featureContext, statusOf(session));
      expect(failing?.state, FeatureHealthState.failing);
      expect(failing?.reason, "Pixel 9 couldn't open the last link you sent");
      expect(
        failing?.help,
        'It waits in Activity on Pixel 9, with Copy and Open.',
      );
    });

    testWidgets('a device without Continue needs an update', (tester) async {
      final ui = await start(tester);

      final health = ui.healthFor(
        featureContext,
        statusOf(_Session(hasContinue: false)),
      );

      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, 'Needs a Ferret update on Pixel 9');
    });
  });
}
