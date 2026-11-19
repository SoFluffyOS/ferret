import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

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

/// Says the same thing every time, without touching the network.
class _FixedDoctor extends ConnectionDoctor {
  _FixedDoctor(super.engine, this.checks);

  final List<DoctorCheck> checks;

  @override
  Stream<List<DoctorCheck>> diagnose(String? deviceId) => Stream.value(checks);
}

final _pixel = TrustedDevice(
  id: 'a',
  name: 'Pixel 9',
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026, 11, 1),
);

void main() {
  late FerretEngine engine;

  Future<void> open(WidgetTester tester, List<DoctorCheck> checks) async {
    final started = await tester.runAsync(() async {
      final engine = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: const LocalDevice(
          name: 'MacBook Air',
          platform: .PLATFORM_MACOS,
          formFactor: .FORM_FACTOR_LAPTOP,
        ),
        features: const [],
        discovery: MemoryDiscoveryBus().join(),
        port: 0,
      );
      await engine.trustStore.save(_pixel);
      return engine;
    });
    engine = started ?? (throw StateError('no engine'));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(engine.stop);
    });

    await tester.pumpWidget(
      testApp(
        ShellScope(
          features: const [],
          featureContext: FeatureContext(
            engine: engine,
            navigatorKey: GlobalKey<NavigatorState>(),
            notifier: _QuietNotifier(),
          ),
          child: DoctorPage(
            deviceId: _pixel.id,
            doctorFor: (engine) => _FixedDoctor(engine, checks),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  ButtonVariant? variantOf(WidgetTester tester, String label) => tester
      .widgetList<Button>(find.byType(Button))
      .where((button) => button.label == label)
      .firstOrNull
      ?.variant;

  testWidgets('a real fix is the one filled button; the helper ones are '
      'links', (tester) async {
    await open(tester, const [
      DoctorCheck(
        kind: .accepted,
        status: .problem,
        fixes: [.pairAgain, .connectByAddress],
      ),
    ]);

    expect(variantOf(tester, 'Pair again'), ButtonVariant.primary);
    expect(variantOf(tester, 'Try again'), ButtonVariant.ghost);
    expect(variantOf(tester, 'Connect by address'), isNull);
    expect(variantOf(tester, 'Copy diagnostics'), isNull);
    expect(find.text('Connect by address'), findsOneWidget);
    expect(find.text('Copy diagnostics'), findsOneWidget);
  });

  testWidgets('with nothing to fix, Try again holds the filled button', (
    tester,
  ) async {
    await open(tester, const [
      DoctorCheck(
        kind: .reachable,
        status: .problem,
        detail: '192.168.1.20',
        fixes: [.connectByAddress],
      ),
    ]);

    expect(variantOf(tester, 'Try again'), ButtonVariant.primary);
    expect(
      tester
          .widgetList<Button>(find.byType(Button))
          .where((button) => button.variant == ButtonVariant.primary),
      hasLength(1),
    );
    expect(find.text('Connect by address'), findsOneWidget);
  });

  testWidgets('a network that keeps devices apart suggests the phone\'s '
      'hotspot', (tester) async {
    await open(tester, const [
      DoctorCheck(kind: .isolated, status: .problem),
    ]);

    expect(
      find.textContaining(
        "Turn on Pixel 9's hotspot and join it from this Mac",
      ),
      findsOneWidget,
    );
  });

  testWidgets('no hotspot line when the network is not the problem', (
    tester,
  ) async {
    await open(tester, const [
      DoctorCheck(kind: .accepted, status: .problem, fixes: [.pairAgain]),
    ]);

    expect(find.textContaining('hotspot'), findsNothing);
  });
}
