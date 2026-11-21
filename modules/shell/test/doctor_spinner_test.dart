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

/// Still knocking, and never done, like a device that takes its time.
class _KnockingDoctor extends ConnectionDoctor {
  _KnockingDoctor(super.engine);

  @override
  Stream<List<DoctorCheck>> diagnose(String? deviceId) => Stream.value(const [
    DoctorCheck(kind: .reachable, status: .running),
  ]);
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
  Future<void> open(WidgetTester tester) async {
    final engine = await tester.runAsync(() async {
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
    final started = engine ?? (throw StateError('no engine'));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(started.stop);
    });

    await tester.pumpWidget(
      testApp(
        ShellScope(
          features: const [],
          featureContext: FeatureContext(
            engine: started,
            navigatorKey: GlobalKey<NavigatorState>(),
            notifier: _QuietNotifier(),
          ),
          child: DoctorPage(
            deviceId: _pixel.id,
            doctorFor: _KnockingDoctor.new,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// How often the ring beside "Knocking on Pixel 9…" was told to move
  /// over half a second.
  Future<int> stepsOverHalfASecond(WidgetTester tester) async {
    final row = find.ancestor(
      of: find.text('Knocking on Pixel 9…'),
      matching: find.byType(DoctorCheckRow),
    );
    final painters = tester
        .widgetList<CustomPaint>(
          find.descendant(of: row, matching: find.byType(CustomPaint)),
        )
        .map((paint) => paint.painter)
        .whereType<ProgressRingPainter>()
        .toList();
    expect(painters, hasLength(1), reason: 'a ring, not a still glyph');

    final clock = painters.single.clock;
    expect(clock, same(LoadingClock.instance));
    expect(LoadingClock.instance.isRunning, isTrue);

    final before = clock.value;
    var steps = 0;
    void count() => steps++;
    clock.addListener(count);
    await tester.pump(const Duration(milliseconds: 500));
    clock.removeListener(count);
    expect(clock.value, greaterThan(before));

    return steps;
  }

  testWidgets('the ring beside Knocking on… turns', (tester) async {
    await open(tester);

    expect(await stepsOverHalfASecond(tester), greaterThan(10));
  });

  testWidgets('it keeps turning while a menubar popover is open and Ferret '
      'is not the active app', (tester) async {
    await open(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    expect(await stepsOverHalfASecond(tester), greaterThan(10));
  });
}
