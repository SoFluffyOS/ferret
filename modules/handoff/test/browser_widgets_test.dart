import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:provider/provider.dart';

import 'support/browser_fakes.dart';
import 'support/fakes.dart';

void main() {
  Future<({HandoffViewModel viewModel, BrowserBridge browser})> build({
    int? port = BrowserBridgeServer.firstPort,
  }) async {
    final host = await FakeHost.create();
    final feature = await startedFeature(host: host, opener: FakeOpener());
    final browser = BrowserBridge(
      feature: feature,
      isSupported: true,
      server: IdleServer(port: port),
    );
    await browser.start();
    final handoff = FerretHandoff(
      api: FakeHandoffApi(),
      isAndroid: false,
      isMacOS: false,
    );
    final viewModel = HandoffViewModel(
      feature: feature,
      bridge: HandoffBridge(
        feature: feature,
        engine: host,
        notifier: FakeNotifier(),
        handoff: handoff,
        pickDevice: (_) async => null,
        strings: () => lookupHandoffLocalizations(const .new('en')),
      ),
      handoff: handoff,
      browser: browser,
    );
    addTearDown(viewModel.dispose);
    addTearDown(browser.stop);
    addTearDown(feature.stop);
    return (viewModel: viewModel, browser: browser);
  }

  Future<void> show(
    WidgetTester tester,
    HandoffViewModel viewModel,
    Widget child,
  ) => tester.pumpWidget(
    testApp(ChangeNotifierProvider.value(value: viewModel, child: child)),
  );

  testWidgets('a browser waiting to pair shows its code on the home card', (
    tester,
  ) async {
    final setup = await tester.runAsync(build);
    if (setup == null) {
      fail('Setup failed');
    }

    final channel = FakeChannel();
    await tester.runAsync(() async {
      setup.browser.attach(channel);
      channel
        ..say({'type': 'hello', 'v': 1, 'browser': 'Brave'})
        ..say({'type': 'pair', 'id': 'p', 'code': '246810'});
      await pumpEventQueue();
    });
    await show(tester, setup.viewModel, const HandoffHomeFrame());
    await tester.pump();

    expect(find.text('Allow Brave to use Ferret?'), findsOneWidget);
    expect(find.textContaining('246 810'), findsOneWidget);

    await tester.tap(find.text('Allow'));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();

    expect(find.text('Allow Brave to use Ferret?'), findsNothing);
    expect(channel.ofType('paired'), hasLength(1));
  });

  testWidgets('settings list allowed browsers and remove them', (
    tester,
  ) async {
    final setup = await tester.runAsync(build);
    if (setup == null) {
      fail('Setup failed');
    }

    await tester.runAsync(() async {
      final channel = FakeChannel();
      setup.browser.attach(channel);
      channel
        ..say({'type': 'hello', 'v': 1, 'browser': 'Firefox'})
        ..say({'type': 'pair', 'code': '123456'});
      await pumpEventQueue();
      await setup.browser.answerPair(
        setup.browser.pairRequests.single.id,
        allow: true,
      );
      await pumpEventQueue();
    });
    await show(tester, setup.viewModel, const BrowserSettingsFrame());
    await tester.pump();

    expect(find.text('Firefox'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();

    expect(find.text('Firefox'), findsNothing);
    expect(find.textContaining('No browser yet'), findsOneWidget);
  });

  testWidgets('taken ports are explained with a retry', (tester) async {
    final setup = await tester.runAsync(() => build(port: null));
    if (setup == null) {
      fail('Setup failed');
    }

    await show(tester, setup.viewModel, const BrowserSettingsFrame());

    expect(find.textContaining('ports 47650 to 47654'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
