import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/find.dart';
import 'package:find/ui/frames/frames.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/find.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

void main() {
  late FakeFindPlatform platform;
  late FakeHost host;
  late FakeSession pixel;
  late FindFeature feature;
  late FindViewModel viewModel;

  /// The host's keys need real async; everything else runs in the test's
  /// fake zone so taps and timers stay in step with pumps.
  Future<void> start(
    WidgetTester tester, {
    RingAbilities? abilities,
    Map<String, Object?>? settings,
  }) async {
    platform = FakeFindPlatform();
    if (abilities != null) {
      platform.abilitiesNow = abilities;
    }

    final created = await tester.runAsync(
      () => FakeHost.create(settings: settings),
    );
    if (created == null) {
      fail('The host should start');
    }

    host = created;
    pixel = FakeSession('pixel', name: 'Pixel');
    host.sessions = [pixel];
    feature = FindFeature(platform: () => platform);
    await feature.start(host);
    viewModel = FindViewModel(feature);
  }

  /// Stops the feature before the test ends, so no ring timer is left.
  /// Stopping awaits stream cancels, which only finish outside the fake zone.
  Future<void> finish(WidgetTester tester) async {
    viewModel.dispose();
    await tester.runAsync(feature.stop);
    await tester.pump();
  }

  Widget withViewModel(Widget child) =>
      testApp(ChangeNotifierProvider.value(value: viewModel, child: child));

  Widget settingsFor(FindPlatformKind kind) => testApp(
    ChangeNotifierProvider(
      create: (_) => FindSettingsViewModel(feature, platform: kind),
      child: const FindSettingsFrame(),
    ),
  );

  group('home card', () {
    testWidgets('stays out of the way while nothing rings', (tester) async {
      await start(tester);

      await tester.pumpWidget(withViewModel(const FindCardFrame()));

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.text('Found it'), findsNothing);

      await finish(tester);
    });

    testWidgets('shows Found it while this device rings', (tester) async {
      await start(tester);
      await tester.pumpWidget(withViewModel(const FindCardFrame()));

      await feature.onEnvelope(pixel, envelopeOf(RingRequest()));
      await tester.pump();

      expect(find.byType(FeatureCard), findsOneWidget);
      expect(find.text('This device is ringing'), findsOneWidget);
      expect(find.text('Pixel is looking for this device.'), findsOneWidget);

      await tester.tap(find.text('Found it'));
      await tester.pump();
      await tester.pump();

      expect(platform.playing, isNull);
      expect(feature.localRing.reason, StopReason.STOP_REASON_FOUND);
      expect(find.text('Found it'), findsNothing);

      await finish(tester);
    });

    testWidgets('a ring to another device has Stop', (tester) async {
      await start(tester);
      pixel.answer = (request) => switch (request) {
        RingRequest() => RingStatus(
          state: .RING_STATE_RINGING,
          remainingMs: 120000,
        ),
        _ => RingStatus(
          state: .RING_STATE_STOPPED,
          reason: .STOP_REASON_STOPPED_REMOTELY,
        ),
      };
      await tester.pumpWidget(withViewModel(const FindCardFrame()));

      await feature.ring('pixel');
      await tester.pump();

      expect(find.text('Ringing Pixel…'), findsOneWidget);

      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();

      expect(pixel.requests.last, isA<StopRingRequest>());
      expect(find.text('Stopped ringing Pixel.'), findsOneWidget);
      expect(find.text('Ring again'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('a device that did not answer gets a reason and a retry', (
      tester,
    ) async {
      await start(tester);
      await tester.pumpWidget(withViewModel(const FindCardFrame()));

      await feature.ring('pixel');
      await tester.pump();

      expect(find.text("Pixel didn't answer."), findsOneWidget);
      expect(
        find.text(
          'Make sure Pixel is on and on the same Wi-Fi, then ring again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ring again'), findsOneWidget);

      await finish(tester);
    });
  });

  testWidgets('the ringing screen has a big Found it', (tester) async {
    await start(tester, settings: {FindSettings.ringOnSilentKey: false});
    await feature.onEnvelope(pixel, envelopeOf(RingRequest()));

    await tester.pumpWidget(
      withViewModel(const SizedBox(height: 600, child: RingingFrame())),
    );

    expect(find.text('Ferret is ringing'), findsOneWidget);
    expect(
      find.text('This device is on silent, so it only vibrates.'),
      findsOneWidget,
    );
    final button = tester.getSize(find.text('Found it'));
    expect(button.height, greaterThan(0));

    await tester.tap(find.text('Found it'));
    await tester.pump();
    await tester.pump();

    expect(feature.localRing.isRinging, isFalse);

    await finish(tester);
  });

  group('settings', () {
    const missingAccess = RingAbilities(
      controlsVolume: true,
      needsDndAccess: true,
      hasTorch: true,
      showsOwnAlert: true,
    );

    testWidgets('Android explains Do Not Disturb access and re-checks', (
      tester,
    ) async {
      await start(tester, abilities: missingAccess);
      await tester.pumpWidget(settingsFor(.android));

      expect(find.text('Ring on silent'), findsOneWidget);
      expect(find.text('Flash the torch'), findsOneWidget);
      expect(find.text('Do Not Disturb access is off'), findsOneWidget);

      await tester.tap(find.text('Allow in Settings'));
      await tester.pump();
      expect(platform.dndOpened, 1);

      final viewModel = Provider.of<FindSettingsViewModel>(
        tester.element(find.byType(FindSettingsFrame)),
        listen: false,
      );
      await viewModel.onResumed();
      await tester.pump();
      expect(
        find.text(
          'Still off. Find Ferret in the list, turn it on, then come back.',
        ),
        findsOneWidget,
      );

      platform.abilitiesNow = const RingAbilities(
        controlsVolume: true,
        needsDndAccess: true,
        dndAccessGranted: true,
        hasTorch: true,
        showsOwnAlert: true,
      );
      await viewModel.onResumed();
      await tester.pump();

      expect(find.text('Rings through Do Not Disturb.'), findsOneWidget);
      expect(find.text('Allow in Settings'), findsNothing);

      await finish(tester);
    });

    testWidgets('turning ringing on silent off hides the permission ask', (
      tester,
    ) async {
      await start(
        tester,
        abilities: missingAccess,
        settings: {FindSettings.ringOnSilentKey: false},
      );

      await tester.pumpWidget(settingsFor(.android));

      expect(find.text('Allow in Settings'), findsNothing);

      await finish(tester);
    });

    testWidgets('says so when Settings cannot open', (tester) async {
      await start(tester, abilities: missingAccess);
      platform.failOpen = true;
      await tester.pumpWidget(settingsFor(.android));

      await tester.tap(find.text('Allow in Settings'));
      await tester.pump();

      expect(find.textContaining("Couldn't open Settings"), findsOneWidget);

      await finish(tester);
    });

    testWidgets('Android asks for full-screen notices when denied', (
      tester,
    ) async {
      await start(
        tester,
        abilities: const RingAbilities(
          controlsVolume: true,
          needsDndAccess: true,
          dndAccessGranted: true,
          fullScreenAllowed: false,
        ),
      );
      await tester.pumpWidget(settingsFor(.android));

      await tester.tap(find.text('Allow in Settings'));
      await tester.pump();

      expect(platform.fullScreenOpened, 1);

      await finish(tester);
    });

    testWidgets('iPhone is honest about needing Ferret open', (tester) async {
      await start(
        tester,
        abilities: const RingAbilities(
          ringsInBackground: false,
          ignoresSilentSwitch: true,
        ),
      );

      await tester.pumpWidget(settingsFor(.ios));

      expect(find.text('Ring on silent'), findsNothing);
      expect(find.textContaining('only while Ferret is open'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('a Linux box without a player says it cannot ring', (
      tester,
    ) async {
      await start(tester, abilities: const RingAbilities(canPlaySound: false));

      await tester.pumpWidget(settingsFor(.desktop));

      expect(find.textContaining('No sound player found'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('the test ring rings this device briefly', (tester) async {
      await start(tester);
      await tester.pumpWidget(settingsFor(.macos));

      await tester.tap(find.text('Test ring'));
      await tester.pump();

      expect(platform.alerts, hasLength(1));
      expect(
        feature.localRing.endsAt?.difference(
          feature.localRing.startedAt ?? DateTime(0),
        ),
        RingController.minDuration,
      );

      await finish(tester);
    });
  });
}
