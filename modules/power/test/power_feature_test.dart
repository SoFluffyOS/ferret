import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power/power.dart';

import 'helpers/fakes.dart';

void main() {
  const shizukuWaiting = PowerStatus(supported: true, shizuku: .notAuthorized);
  const shizukuReady = PowerStatus(supported: true, shizuku: .ready);
  const rooted = PowerStatus(supported: true, root: .found);

  test('the feature and its UI share one id and no chip', () {
    final ui = PowerFeatureUi(feature: PowerFeature());

    expect(ui.featureId, PowerFeature.featureId);
    expect(ui.feature.id, PowerFeature.featureId);
    expect(ui.uiChanges, same(ui.viewModel));
  });

  testWidgets('coming back to the app reads the phone again', (tester) async {
    late PowerHarness harness;
    await tester.runAsync(() async {
      harness = await PowerHarness.start(status: shizukuWaiting);
    });
    final ui = PowerFeatureUi(feature: harness.feature);
    addTearDown(() async {
      ui.dispose();
      await tester.runAsync(harness.dispose);
    });
    await ui.onAppStarted(_NoContext());
    expect(ui.viewModel.status.shizuku, ShizukuStatus.notAuthorized);

    harness.phone.setQuietly(shizukuReady);
    for (final state in <AppLifecycleState>[
      .inactive,
      .hidden,
      .paused,
      .hidden,
      .inactive,
      .resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.runAsync(settle);

    expect(ui.viewModel.status.shizuku, ShizukuStatus.ready);
    expect(ui.viewModel.prompt, PowerPrompt.allowShizuku);
    expect(ui.hasHomeCard(_NoContext()), isFalse);
  });

  test('a fresh install uses nothing, whatever the phone offers', () async {
    final harness = await PowerHarness.start(
      status: const PowerStatus(supported: true, shizuku: .ready, root: .found),
    );
    addTearDown(harness.dispose);

    expect(harness.feature.tier, PowerTier.standard);
    expect(harness.phone.rootRequests, 0);
    expect(harness.phone.shellCalls, isEmpty);
  });

  test('saved choices are applied at start', () async {
    final harness = await PowerHarness.start(
      status: shizukuReady,
      settings: {PowerSettings.shizukuEnabledKey: true},
    );
    addTearDown(harness.dispose);

    expect(harness.feature.tier, PowerTier.shizuku);
  });

  test('allowing Shizuku is remembered, and so is stopping', () async {
    final harness = await PowerHarness.start(status: shizukuWaiting);
    addTearDown(harness.dispose);
    var changes = 0;
    harness.feature.changes.listen((_) => changes++);

    final allowed = await harness.feature.allowShizuku();
    await settle();

    expect(allowed, isTrue);
    expect(harness.feature.settings.shizukuEnabled, isTrue);
    expect(harness.feature.tier, PowerTier.shizuku);
    expect(changes, greaterThan(0));

    await harness.feature.stopUsingShizuku();

    expect(harness.feature.settings.shizukuEnabled, isFalse);
    expect(harness.feature.tier, PowerTier.standard);
  });

  test('a refused Shizuku dialog is not remembered as a yes', () async {
    final harness = await PowerHarness.start(status: shizukuWaiting);
    addTearDown(harness.dispose);
    harness.phone.shizukuAnswer = false;

    final allowed = await harness.feature.allowShizuku();

    expect(allowed, isFalse);
    expect(harness.feature.settings.shizukuEnabled, isFalse);
  });

  test('root is asked for only by useRoot, and its answer is kept', () async {
    final harness = await PowerHarness.start(status: rooted);
    addTearDown(harness.dispose);
    expect(harness.phone.rootRequests, 0);

    final allowed = await harness.feature.useRoot();

    expect(allowed, isTrue);
    expect(harness.phone.rootRequests, 1);
    expect(harness.feature.settings.rootEnabled, isTrue);
    expect(harness.feature.tier, PowerTier.root);

    await harness.feature.stopUsingRoot();

    expect(harness.feature.settings.rootEnabled, isFalse);
    expect(harness.feature.tier, PowerTier.standard);
  });

  group('the home card', () {
    Future<PowerPrompt?> promptFor(
      PowerStatus status, {
      Map<String, Object?>? settings,
    }) async {
      final harness = await PowerHarness.start(
        status: status,
        settings: settings,
      );
      addTearDown(harness.dispose);
      return harness.viewModel.prompt;
    }

    test('stays away when there is no step to take', () async {
      expect(await promptFor(const PowerStatus(supported: true)), isNull);
      expect(await promptFor(PowerStatus.unsupported), isNull);
      expect(
        await promptFor(
          shizukuReady,
          settings: {PowerSettings.shizukuEnabledKey: true},
        ),
        isNull,
      );
    });

    test('offers the next step of what the phone already has', () async {
      expect(
        await promptFor(
          const PowerStatus(supported: true, shizuku: .notRunning),
        ),
        PowerPrompt.startShizuku,
      );
      expect(await promptFor(shizukuWaiting), PowerPrompt.allowShizuku);
      expect(await promptFor(rooted), PowerPrompt.useRoot);
    });

    test('says so when root was taken away', () async {
      final harness = await PowerHarness.start(
        status: rooted,
        settings: {PowerSettings.rootEnabledKey: true},
      );
      addTearDown(harness.dispose);
      expect(harness.viewModel.prompt, isNull);

      harness.phone.emit(rooted);
      await settle();

      expect(harness.viewModel.prompt, PowerPrompt.rootLost);
      expect(harness.viewModel.prompt?.isProblem, isTrue);
    });
  });
}

/// Power-ups never read the context they are handed at startup.
class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
