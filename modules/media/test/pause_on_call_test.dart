import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_media/ferret_media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'support/fake_host.dart';
import 'support/fake_media_backend.dart';
import 'support/test_app.dart';

void main() {
  late FakeMediaBackend backend;
  late MediaFeature feature;

  setUp(() async {
    backend = FakeMediaBackend();
    feature = MediaFeature(backend: () => backend);
    await feature.start(FakeHost());
    await Future<void>.delayed(Duration.zero);
    backend.commands.clear();
  });

  tearDown(() => feature.stop());

  group('pausing for a call', () {
    test('pauses only what plays here and returns it', () async {
      backend.current = [
        playerInfo(),
        playerInfo(id: 'music', status: PlayerStatus.paused),
      ];

      final paused = await feature.pauseLocalPlayback();

      expect(paused, ['spotify']);
      expect(backend.commands.map((command) => command.action), [
        PlayerAction.pause,
      ]);
    });

    test('resumes only what it paused and is still paused', () async {
      backend.current = [
        playerInfo(status: PlayerStatus.paused),
        playerInfo(id: 'music', status: PlayerStatus.paused),
        playerInfo(id: 'podcasts'),
      ];

      await feature.resumeLocalPlayback(['spotify', 'podcasts']);

      expect(backend.commands.map((command) => command.playerId), [
        'spotify',
      ]);
      expect(backend.commands.single.action, PlayerAction.play);
    });

    test('pauses nothing without access, and never asks for it', () async {
      backend
        ..accessState = MediaAccess.notGranted
        ..current = [playerInfo()];

      final paused = await feature.pauseLocalPlayback();

      expect(paused, isEmpty);
      expect(backend.commands, isEmpty);
      expect(backend.accessRequests, 0);
    });

    test('pauses nothing on a device without players', () async {
      final iphone = MediaFeature();
      await iphone.start(FakeHost());

      expect(await iphone.pauseLocalPlayback(), isEmpty);
      await iphone.stop();
    });

    test('is on by default and can be turned off', () async {
      expect(feature.pauseOnCall, isTrue);

      await feature.setPauseOnCall(false);

      expect(feature.pauseOnCall, isFalse);
    });
  });

  group('the home card', () {
    test('has nothing to show while nothing plays elsewhere', () {
      final ui = MediaFeatureUi(feature: feature, platform: .other);

      expect(ui.uiChanges, same(ui.viewModel));
      expect(ui.viewModel.selected, isNull);
    });
  });

  testWidgets('the settings switch turns pausing during calls off', (
    tester,
  ) async {
    final model = MediaViewModel(feature, platform: .android);

    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: model,
          child: const MediaSettingsFrame(),
        ),
      ),
    );
    expect(find.text('Pause during calls'), findsOneWidget);

    final row = find.ancestor(
      of: find.text('Pause during calls'),
      matching: find.byType(SettingSwitchRow),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byType(SwitchToggle)),
    );
    // The switch reports a tap after its own short debounce.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(model.pauseOnCall, isFalse);
    expect(feature.pauseOnCall, isFalse);
    model.dispose();
  });
}
