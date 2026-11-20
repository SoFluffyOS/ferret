import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wake/wake.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

class _Quiet implements LocalNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lists the offline actions and the status line for [status].
class _Row extends StatelessWidget {
  const _Row({required this.ui, required this.context, required this.status});

  final WakeFeatureUi ui;
  final FeatureContext context;
  final DeviceStatus status;

  @override
  Widget build(BuildContext buildContext) => ListenableBuilder(
    listenable: ui.uiChanges,
    builder: (buildContext, _) => Column(
      children: [
        Text(ui.offlineStatus(buildContext, context, status) ?? 'Last seen'),
        for (final action in ui.offlineActions(buildContext, context, status))
          GestureDetector(
            onTap: action.onPressed,
            child: Text(
              '${action.label}${switch (action.onPressed) {
                null => ' (off)',
                _ => '',
              }}',
            ),
          ),
      ],
    ),
  );
}

void main() {
  testWidgets(
    'Wake, then Waking… until the wait ends, then Didn\'t wake and help',
    (tester) async {
      final host = await tester.runAsync(FakeHost.create);
      if (host == null) {
        fail('The host should start');
      }

      final sender = FakeSender();
      final ui = WakeFeatureUi(
        feature: WakeFeature(
          isComputer: false,
          sender: sender,
          readCards: () async => const [],
          wakeTimeout: const Duration(milliseconds: 50),
        ),
      );
      await tester.runAsync(() async {
        await ui.feature.start(host);
        await host.trustStore.save(computer(wake: wiredWake()));
      });
      final navigatorKey = GlobalKey<NavigatorState>();
      final context = FeatureContext(
        engine: FakeEngine(),
        navigatorKey: navigatorKey,
        notifier: _Quiet(),
      );
      final status = DeviceStatus(computer(wake: wiredWake()), null);

      await tester.pumpWidget(
        testApp(
          _Row(ui: ui, context: context, status: status),
          navigatorKey: navigatorKey,
        ),
      );
      expect(find.text('Wake'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('Wake'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(find.text('Waking MacBook Pro… (up to a minute)'), findsOneWidget);
      expect(find.text('Waking… (off)'), findsOneWidget);
      expect(sender.sends, hasLength(1));

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(find.text("Didn't wake"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('How to turn on'));
      await tester.pumpAndSettle();
      expect(find.byType(WakeHelpPage), findsOneWidget);
      expect(find.text('What MacBook Pro told Ferret'), findsOneWidget);
      expect(find.text('Cable · Wake-on-LAN is on'), findsOneWidget);
    },
  );

  testWidgets('a computer that shared nothing has no Wake', (tester) async {
    final ui = WakeFeatureUi(
      feature: WakeFeature(isComputer: false, sender: FakeSender()),
    );
    final context = FeatureContext(
      engine: FakeEngine(),
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: _Quiet(),
    );

    await tester.pumpWidget(
      testApp(
        _Row(
          ui: ui,
          context: context,
          status: DeviceStatus(computer(), null),
        ),
      ),
    );

    expect(find.text('Wake'), findsNothing);
    expect(find.text('Last seen'), findsOneWidget);
  });

  testWidgets('the help page puts the computer\'s own system first', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        const WakeHelpPage(
          platform: .PLATFORM_WINDOWS,
          deviceName: 'Family PC',
          fromIphone: true,
        ),
        scroll: false,
      ),
    );

    final iphone = tester.getTopLeft(find.text('From an iPhone')).dy;
    final windows = tester.getTopLeft(find.text('Windows')).dy;
    final mac = tester.getTopLeft(find.text('Mac')).dy;
    expect(iphone, lessThan(windows));
    expect(windows, lessThan(mac));
    expect(
      find.text('No network card to wake it by yet. Open Ferret on it once.'),
      findsOneWidget,
    );
  });
}
