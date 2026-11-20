import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'support/fakes.dart';

void main() {
  Future<({HandoffViewModel viewModel, HandoffFeature feature})> build(
    WidgetTester tester, {
    bool isAndroid = false,
  }) async {
    final host = await FakeHost.create();
    final feature = await startedFeature(host: host, opener: FakeOpener());
    final handoff = FerretHandoff(
      api: FakeHandoffApi(),
      isAndroid: isAndroid,
      isMacOS: false,
    );
    final bridge = HandoffBridge(
      feature: feature,
      engine: host,
      notifier: FakeNotifier(),
      handoff: handoff,
      pickDevice: (_) async => null,
      strings: () => lookupHandoffLocalizations(const .new('en')),
    );
    final viewModel = HandoffViewModel(
      feature: feature,
      bridge: bridge,
      handoff: handoff,
    );
    addTearDown(feature.stop);
    addTearDown(viewModel.dispose);
    return (viewModel: viewModel, feature: feature);
  }

  testWidgets('the card stays hidden with nothing to continue', (
    tester,
  ) async {
    final setup = await tester.runAsync(() => build(tester));
    if (setup == null) {
      fail('Setup failed');
    }

    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: setup.viewModel,
          child: const ContinueCardFrame(),
        ),
      ),
    );

    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('a suggestion shows, opens and can be dismissed', (
    tester,
  ) async {
    final setup = await tester.runAsync(() => build(tester));
    if (setup == null) {
      fail('Setup failed');
    }

    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: setup.viewModel,
          child: const ContinueCardFrame(),
        ),
      ),
    );
    await tester.runAsync(() async {
      await setup.feature.receivePublished(
        pixel,
        webActivity('a', title: 'Cats'),
      );
      await setup.feature.receivePublished(
        tablet,
        webActivity('b', title: 'Dogs'),
      );
    });
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Continue “Cats” from Pixel'), findsOneWidget);
    expect(find.text('Continue “Dogs” from Tablet'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x).first);
    await tester.pump();
    expect(find.text('Continue “Dogs” from Tablet'), findsNothing);

    await tester.runAsync(() async {
      await tester.tap(find.text('Open'));
      await pumpEventQueue();
    });
    await tester.pump();
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('settings toggle passive suggestions', (tester) async {
    final setup = await tester.runAsync(() => build(tester));
    if (setup == null) {
      fail('Setup failed');
    }

    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: setup.viewModel,
          child: const HandoffSettingsFrame(),
        ),
      ),
    );

    expect(find.text("Suggest what I'm doing"), findsOneWidget);
    expect(find.text('Read the current browser page'), findsNothing);
    expect(find.text('Continue from any app'), findsNothing);

    await tester.runAsync(() => setup.viewModel.setPassiveEnabled(false));
    await tester.pump();

    expect(setup.viewModel.passiveEnabled, isFalse);
  });

  testWidgets('on Android, settings explain the assistant', (tester) async {
    final setup = await tester.runAsync(
      () => build(tester, isAndroid: true),
    );
    if (setup == null) {
      fail('Setup failed');
    }

    await tester.runAsync(setup.viewModel.refreshAssistant);
    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: setup.viewModel,
          child: const SingleChildScrollView(child: HandoffSettingsFrame()),
        ),
      ),
    );

    expect(find.text('Continue from any app'), findsOneWidget);
    expect(find.text("Ferret isn't your assistant yet"), findsOneWidget);
    expect(find.text('Assistant settings'), findsOneWidget);
  });
}
