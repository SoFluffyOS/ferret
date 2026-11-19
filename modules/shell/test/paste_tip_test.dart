import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

final _pixel = TrustedDevice(
  id: 'a',
  name: 'Pixel 9',
  platform: .PLATFORM_ANDROID,
  formFactor: .FORM_FACTOR_PHONE,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026, 11, 1),
);

const _tip =
    'Tired of the Allow Paste question? Settings → Ferret → Paste from '
    'Other Apps → Allow';

void main() {
  late FerretEngine engine;
  late SettingsStore settings;

  Future<void> start(WidgetTester tester) async {
    settings = MemorySettingsStore({TipsFrame.copyDoneKey: true});
    final started = await tester.runAsync(() async {
      final engine = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: settings,
        device: const LocalDevice(
          name: 'iPhone',
          platform: .PLATFORM_IOS,
          formFactor: .FORM_FACTOR_PHONE,
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
  }

  Future<void> showTips(WidgetTester tester) => tester.pumpWidget(
    testApp(
      ShellScope(
        features: const [],
        featureContext: FeatureContext(
          engine: engine,
          navigatorKey: GlobalKey<NavigatorState>(),
          notifier: _QuietNotifier(),
        ),
        child: TipsFrame(
          key: UniqueKey(),
          device: DeviceStatus(_pixel, null),
        ),
      ),
    ),
  );

  Future<void> sendClipboard(WidgetTester tester) async {
    await DeviceActionUsage(settings).record(_pixel.id, 'clipboard.send');
    await tester.pump();
  }

  testWidgets('on iOS the first Send clipboard brings the paste tip, once', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await start(tester);

    await showTips(tester);
    expect(find.text(_tip), findsNothing);

    await sendClipboard(tester);
    expect(find.text(_tip), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pump();
    expect(find.text(_tip), findsNothing);
    expect(settings.get<bool>(TipsFrame.pasteDoneKey), isTrue);

    await sendClipboard(tester);
    await showTips(tester);
    expect(find.text(_tip), findsNothing);
  });

  testWidgets('on iOS the tip waits until dismissed, across launches', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await start(tester);
    await DeviceActionUsage(settings).record(_pixel.id, 'clipboard.send');

    await showTips(tester);

    expect(find.text(_tip), findsOneWidget);
  });

  testWidgets('a Mac never asks before a paste, so it has no paste tip', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await start(tester);
    await settings.set(TipsFrame.dragDoneKey, true);

    await showTips(tester);
    await sendClipboard(tester);

    expect(find.text(_tip), findsNothing);
  });

  group('Show tips again', () {
    testWidgets('brings a waved-off tip back without a restart', (
      tester,
    ) async {
      await start(tester);
      await tester.runAsync(() => settings.set(TipsFrame.dragDoneKey, true));
      await showTips(tester);
      expect(find.textContaining('Try it:'), findsNothing);

      await tester.runAsync(() => Tips(settings).showAgain());
      await tester.pump();

      expect(find.textContaining('Try it:'), findsOneWidget);
      expect(settings.get<bool>(TipsFrame.copyDoneKey), isFalse);
      expect(settings.get<bool>(TipsFrame.dragDoneKey), isFalse);
    });

    test('only what happens after it counts as trying a tip', () async {
      final store = MemorySettingsStore();
      final tips = Tips(store);
      final asked = DateTime(2026, 11, 19, 12);
      expect(tips.countsAsTried(DateTime(2026)), isTrue);
      expect(tips.countsAsTried(null), isTrue);

      await tips.showAgain(now: asked);

      expect(tips.isCopyDone, isFalse);
      expect(
        tips.countsAsTried(asked.subtract(const Duration(days: 1))),
        isFalse,
      );
      expect(tips.countsAsTried(null), isFalse);
      expect(tips.countsAsTried(asked.add(const Duration(seconds: 5))), isTrue);
    });

    testWidgets('the row in About says the tips are back', (tester) async {
      await start(tester);
      await tester.pumpWidget(
        testApp(
          ShellScope(
            features: const [],
            featureContext: FeatureContext(
              engine: engine,
              navigatorKey: GlobalKey<NavigatorState>(),
              notifier: _QuietNotifier(),
            ),
            child: const TipsAgainRow(),
          ),
        ),
      );
      expect(settings.get<bool>(TipsFrame.copyDoneKey), isTrue);

      await tester.tap(find.text('Show tips again'));
      await tester.pump();

      expect(find.text('Tips are back, one at a time.'), findsOneWidget);
      expect(settings.get<bool>(TipsFrame.copyDoneKey), isFalse);
      expect(settings.get<int>(Tips.againSinceKey), isNotNull);
    });
  });
}
