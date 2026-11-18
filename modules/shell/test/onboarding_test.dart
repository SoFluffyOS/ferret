import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:provider/provider.dart';
import 'package:shell/shell.dart';
import 'package:transport/transport.dart';

import 'test_app.dart';

void main() {
  testWidgets('a newcomer goes from welcome to ready and is remembered', (
    tester,
  ) async {
    final engine = await tester.runAsync(
      () => FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: const LocalDevice(
          name: 'MacBook',
          platform: .PLATFORM_MACOS,
          formFactor: .FORM_FACTOR_LAPTOP,
        ),
        discovery: _SilentDiscovery(),
        port: 0,
      ),
    );
    if (engine == null) {
      fail('Engine did not start');
    }

    final featureContext = FeatureContext(
      engine: engine,
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: _NoNotifier(),
    );
    var done = false;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: EngineHost(engine),
        child: ShellScope(
          features: const [],
          featureContext: featureContext,
          child: testApp(OnboardingPage(onDone: () => done = true)),
        ),
      ),
    );

    expect(find.text('Your devices, working together'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Name this device'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Desk Mac');
    await tester.tap(find.text('Continue'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('Pair your other device'), findsOneWidget);
    expect(engine.device.name, 'Desk Mac');
    await tester.tap(find.text('Do this later'));
    await tester.pumpAndSettle();

    expect(find.text("You're all set"), findsOneWidget);
    await tester.tap(find.text('Start using Ferret'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );

    expect(done, isTrue);
    expect(engine.settings.get<bool>(OnboardingPage.doneKey), isTrue);
  });
}

class _SilentDiscovery implements Discovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}

class _NoNotifier implements LocalNotifier {
  @override
  Future<void> show(LocalNotice notice) async {}

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}
