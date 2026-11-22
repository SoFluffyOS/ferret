import 'package:ferret_media/ferret_media.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media/media.dart';
import 'package:protocol/media.dart';
import 'package:provider/provider.dart';

import 'support/fake_host.dart';
import 'support/fake_media_backend.dart';
import 'support/test_app.dart';

RemotePlayer _remote({bool playing = true}) => RemotePlayer(
  deviceId: 'pixel',
  deviceName: 'Pixel',
  player: MediaPlayer(
    playerId: 'spotify',
    appName: 'Spotify',
    title: 'Teardrop',
    artist: 'Massive Attack',
    positionMs: Int64(83000),
    durationMs: Int64(330000),
    status: switch (playing) {
      true => .MEDIA_PLAYBACK_STATUS_PLAYING,
      false => .MEDIA_PLAYBACK_STATUS_PAUSED,
    },
    actions: [.MEDIA_ACTION_TOGGLE, .MEDIA_ACTION_NEXT],
  ),
  positionAtMs: 0,
  lastActiveAtMs: 0,
);

void main() {
  group('NowPlayingCard', () {
    testWidgets('shows the item, its device and the progress', (tester) async {
      await tester.pumpWidget(
        testApp(
          NowPlayingCard(
            player: _remote(playing: false),
            now: () => 0,
            continuing: false,
            continueKeepsPosition: true,
            onToggle: () {},
            onContinue: () {},
          ),
        ),
      );

      expect(
        find.text('Paused on Pixel\nMassive Attack · Spotify'),
        findsOneWidget,
      );
      expect(find.text('Teardrop'), findsOneWidget);
      expect(find.text('1:23'), findsOneWidget);
      expect(find.text('5:30'), findsOneWidget);
      expect(find.text('Continue here'), findsOneWidget);
    });

    testWidgets('play and continue call back', (tester) async {
      var toggles = 0;
      var continues = 0;
      await tester.pumpWidget(
        testApp(
          NowPlayingCard(
            player: _remote(playing: false),
            now: () => 0,
            continuing: false,
            continueKeepsPosition: true,
            onToggle: () => toggles++,
            onContinue: () => continues++,
          ),
        ),
      );

      await tester.tap(find.byIcon(LucideIcons.play));
      await tester.tap(find.text('Continue here'));
      await tester.pumpAndSettle();

      expect(toggles, 1);
      expect(continues, 1);
    });

    testWidgets('hides Continue here when the item has no link', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NowPlayingCard(
            player: _remote(playing: false),
            now: () => 0,
            continuing: false,
            continueKeepsPosition: false,
          ),
        ),
      );

      expect(find.text('Continue here'), findsNothing);
    });
  });

  group('MediaSettingsFrame', () {
    Future<(MediaViewModel, FakeMediaBackend)> startModel(
      FakeMediaBackend backend,
      MediaPlatform platform,
    ) async {
      final feature = MediaFeature(backend: () => backend);
      await feature.start(FakeHost());
      await Future<void>.delayed(Duration.zero);
      return (MediaViewModel(feature, platform: platform), backend);
    }

    testWidgets('explains Notification access on Android, with a fix', (
      tester,
    ) async {
      final (model, backend) =
          await tester.runAsync(
            () => startModel(
              FakeMediaBackend(accessState: MediaAccess.notGranted),
              .android,
            ),
          ) ??
          (throw StateError('The model should start'));

      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: model,
            child: const MediaSettingsFrame(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Share my media'), findsOneWidget);
      expect(find.textContaining('Notification access'), findsOneWidget);

      await tester.tap(find.text('Open settings'));
      await tester.pump();

      expect(backend.settingsOpened, 1);
      model.dispose();
    });

    testWidgets('says what iPhone can and cannot do', (tester) async {
      tester.view.display.size = const Size(1170, 2532);
      tester.view.display.devicePixelRatio = 3;
      addTearDown(tester.view.display.reset);
      final feature = MediaFeature();
      await tester.runAsync(() => feature.start(FakeHost()));
      final model = MediaViewModel(feature, platform: .ios);

      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: model,
            child: const MediaSettingsFrame(),
          ),
        ),
      );

      expect(find.text('Share my media'), findsNothing);
      expect(find.text('Show media from other devices'), findsOneWidget);
      expect(find.textContaining("iPhone doesn't let apps"), findsOneWidget);
      model.dispose();
    });

    testWidgets('an iPad says iPad', (tester) async {
      tester.view.display.size = const Size(2360, 1640);
      tester.view.display.devicePixelRatio = 2;
      addTearDown(tester.view.display.reset);
      final feature = MediaFeature();
      await tester.runAsync(() => feature.start(FakeHost()));
      final model = MediaViewModel(feature, platform: .ios);

      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: model,
            child: const MediaSettingsFrame(),
          ),
        ),
      );

      expect(find.textContaining("iPad doesn't let apps"), findsOneWidget);
      model.dispose();
    });
  });
}
