import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart' show DeviceInfo;
import 'package:shell/shell.dart';

import 'support/memory_discovery.dart';
import 'test_app.dart';

class _QuietNotifier implements LocalNotifier {
  @override
  Future<void> show(LocalNotice notice) async {}

  @override
  Future<void> cancel(String id) async {}

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}

PairingPrompt _promptFrom(String name) => PairingPrompt(
  device: DeviceInfo(
    id: 'abcdabcdabcdabcd',
    name: name,
    platform: .PLATFORM_WINDOWS,
    formFactor: .FORM_FACTOR_DESKTOP,
  ),
  code: '123456',
  expiresAt: DateTime.now().add(const Duration(minutes: 1)),
);

void main() {
  Future<void> open(WidgetTester tester, PairingPrompt prompt) async {
    final started = await tester.runAsync(
      () => FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: const LocalDevice(
          name: 'SoFluffy',
          platform: .PLATFORM_LINUX,
          formFactor: .FORM_FACTOR_DESKTOP,
        ),
        features: const [],
        discovery: MemoryDiscoveryBus().join(),
        port: 0,
      ),
    );
    final engine = started ?? (throw StateError('no engine'));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(engine.stop);
    });

    await tester.pumpWidget(
      ShellScope(
        features: const [],
        featureContext: FeatureContext(
          engine: engine,
          navigatorKey: GlobalKey<NavigatorState>(),
          notifier: _QuietNotifier(),
        ),
        child: testApp(PairingPromptDialog(prompt: prompt)),
      ),
    );
    await tester.pump();
  }

  testWidgets('the prompt says which kind of device asks', (tester) async {
    await open(tester, _promptFrom('Pixel Desk'));

    expect(find.text('Pair with Pixel Desk · Windows?'), findsOneWidget);
    expect(find.text('Rename'), findsNothing);
  });

  testWidgets('a device with this one\'s own name offers Rename, calmly', (
    tester,
  ) async {
    await open(tester, _promptFrom('sofluffy'));

    expect(find.text('Pair with sofluffy · Windows?'), findsOneWidget);
    expect(
      find.text(
        'This computer is called sofluffy too. Rename it to tell them apart.',
      ),
      findsOneWidget,
    );
    expect(find.text('Rename'), findsOneWidget);

    await tester.tap(find.text('Rename'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Name this device'), findsOneWidget);
  });
}
