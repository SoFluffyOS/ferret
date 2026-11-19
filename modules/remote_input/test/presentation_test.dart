import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart' as wire;
import 'package:protocol/remote_input.dart' hide Key;
import 'package:provider/provider.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

void main() {
  late FakeSession mac;
  late RemoteInputFeature feature;
  late DateTime now;
  late PresentationViewModel viewModel;

  Future<void> start(WidgetTester tester) async {
    await tester.runAsync(() async {
      final host = await FakeHost.create();
      mac = FakeSession('mac', name: 'MacBook Air')
        ..answer = (_) => ControlGrant(version: 1);
      host.sessions = [mac];
      feature = RemoteInputFeature(
        injector: FakeInjector.new,
        locker: const UnsupportedScreenLocker(),
        canBeControlled: false,
        canControl: true,
      );
      await feature.start(host);
      await feature.control('mac');
    });
    now = DateTime(2026, 11, 19, 9);
    viewModel = PresentationViewModel(feature, clock: () => now);
    addTearDown(() async {
      viewModel.dispose();
      await tester.runAsync(feature.stop);
    });
  }

  List<wire.Key> keysSent() => [
    for (final batch in mac.sentOf<InputBatch>())
      for (final event in batch.events)
        if (event.hasKey() && event.key.pressed) event.key.key,
  ];

  Future<void> flush(WidgetTester tester) => tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );

  testWidgets('Next and Back press Page Down and Page Up, as a clicker', (
    tester,
  ) async {
    await start(tester);

    viewModel
      ..next()
      ..previous();
    await flush(tester);

    expect(keysSent(), [wire.Key.KEY_PAGE_DOWN, wire.Key.KEY_PAGE_UP]);
  });

  testWidgets('black screen presses B and flips back', (tester) async {
    await start(tester);

    viewModel.toggleBlack();
    expect(viewModel.isBlack, isTrue);
    viewModel.toggleBlack();
    await flush(tester);

    expect(viewModel.isBlack, isFalse);
    expect(keysSent(), [wire.Key.KEY_B, wire.Key.KEY_B]);
    expect(viewModel.isTiming, isFalse);
  });

  testWidgets('the timer starts with the first slide and restarts', (
    tester,
  ) async {
    await start(tester);
    expect(viewModel.elapsed, Duration.zero);

    viewModel.next();
    now = now.add(const Duration(minutes: 2, seconds: 5));

    expect(viewModel.elapsed, const Duration(minutes: 2, seconds: 5));

    viewModel.restartTimer();
    expect(viewModel.isTiming, isFalse);
  });

  testWidgets('the remote shows the time and its big buttons', (tester) async {
    await start(tester);
    viewModel.next();
    now = now.add(const Duration(minutes: 12, seconds: 3));

    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const SizedBox(height: 600, child: PresentationFrame()),
        ),
      ),
    );

    expect(find.text('12:03'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Black screen'), findsOneWidget);

    await tester.tap(find.text('Black screen'));
    await tester.pump();
    expect(find.text('Show slides'), findsOneWidget);
  });
}
