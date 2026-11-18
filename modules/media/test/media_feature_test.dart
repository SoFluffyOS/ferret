import 'dart:typed_data';

import 'package:ferret_media/ferret_media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';

import 'support/fake_link_opener.dart';
import 'support/fake_media_backend.dart';
import 'support/linked_engines.dart';

void main() {
  late FakeMediaBackend phoneBackend;
  late FakeLinkOpener laptopOpener;
  late LinkedEngines engines;

  int nowMs() => DateTime.now().millisecondsSinceEpoch;

  setUp(() async {
    phoneBackend = FakeMediaBackend();
    laptopOpener = FakeLinkOpener();
    engines = await LinkedEngines.start(
      phoneFeature: MediaFeature(
        backend: () => phoneBackend,
        throttle: const Duration(milliseconds: 100),
      ),
      laptopFeature: MediaFeature(linkOpener: laptopOpener),
    );
    await until(() => phoneBackend.watching);
  });

  tearDown(() => engines.stop());

  PlayerKey phoneKey(String playerId) =>
      PlayerKey(engines.phone.identity.deviceId, playerId);

  test('the feature and its UI share one id', () {
    final ui = MediaFeatureUi(feature: MediaFeature(), platform: .other);

    expect(ui.featureId, MediaFeature.featureId);
    expect(ui.feature.id, MediaFeature.featureId);
  });

  test(
    'what plays on the phone shows on the laptop with its artwork',
    () async {
      final artwork = Uint8List.fromList([0xFF, 0xD8, 1, 2, 3]);
      phoneBackend.emit([
        playerInfo(positionAtMs: nowMs(), artwork: artwork),
      ]);

      await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);
      final remote = engines.laptopMedia.remotePlayers.single;

      expect(remote.deviceName, 'Pixel');
      expect(remote.player.title, 'Teardrop');
      expect(remote.artwork, artwork);
      expect(remote.isPlaying, isTrue);
    },
  );

  test('position ticks are not sent; a pause is', () async {
    final start = nowMs();
    phoneBackend.emit([playerInfo(positionMs: 10000, positionAtMs: start)]);
    await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);

    var updates = 0;
    final subscription = engines.laptopMedia.changes.listen((_) => updates++);
    phoneBackend.emit([
      playerInfo(positionMs: 11000, positionAtMs: start + 1000),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(updates, 0);

    phoneBackend.emit([
      playerInfo(
        positionMs: 11000,
        positionAtMs: start + 1000,
        status: PlayerStatus.paused,
      ),
    ]);
    await until(() => !engines.laptopMedia.remotePlayers.single.isPlaying);
    await subscription.cancel();

    expect(engines.laptopMedia.remotePlayers.single.positionAt(nowMs()), 11000);
  });

  test('commands reach the right player on the phone', () async {
    phoneBackend.emit([
      playerInfo(positionAtMs: nowMs()),
      playerInfo(id: 'youtube', appName: 'YouTube', positionAtMs: nowMs()),
    ]);
    await until(() => engines.laptopMedia.remotePlayers.length == 2);

    final toggled = await engines.laptopMedia.command(
      phoneKey('youtube'),
      .MEDIA_ACTION_TOGGLE,
    );
    final sought = await engines.laptopMedia.command(
      phoneKey('spotify'),
      .MEDIA_ACTION_SEEK,
      positionMs: 120000,
    );

    expect(toggled, CommandOutcome.ok);
    expect(sought, CommandOutcome.ok);
    expect(phoneBackend.commands, [
      (playerId: 'youtube', action: PlayerAction.toggle, positionMs: 0),
      (playerId: 'spotify', action: PlayerAction.seek, positionMs: 120000),
    ]);
  });

  test('a command to a closed player says so', () async {
    phoneBackend.emit([playerInfo(positionAtMs: nowMs())]);
    await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);

    final outcome = await engines.laptopMedia.command(
      phoneKey('gone'),
      .MEDIA_ACTION_NEXT,
    );

    expect(outcome, CommandOutcome.unknownPlayer);
    expect(phoneBackend.commands, isEmpty);
  });

  test('an action the player lacks is refused', () async {
    phoneBackend.emit([
      playerInfo(
        positionAtMs: nowMs(),
        actions: const [PlayerAction.play, PlayerAction.pause],
      ),
    ]);
    await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);

    final outcome = await engines.laptopMedia.command(
      phoneKey('spotify'),
      .MEDIA_ACTION_NEXT,
    );

    expect(outcome, CommandOutcome.unsupported);
  });

  test('turning sharing off clears the laptop and refuses commands', () async {
    phoneBackend.emit([playerInfo(positionAtMs: nowMs())]);
    await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);

    await engines.phoneMedia.setShare(false);
    await until(() => engines.laptopMedia.remotePlayers.isEmpty);
    final outcome = await engines.laptopMedia.command(
      phoneKey('spotify'),
      .MEDIA_ACTION_PLAY,
    );

    expect(phoneBackend.watching, isFalse);
    expect(outcome, CommandOutcome.notShared);
  });

  test(
    'continue here pauses the phone and opens YouTube at the position',
    () async {
      phoneBackend.emit([
        playerInfo(
          id: 'youtube',
          appId: 'com.google.android.youtube',
          appName: 'YouTube',
          contentUri: 'https://www.youtube.com/watch?v=u7K72X4eo_s',
          positionMs: 95000,
          positionAtMs: nowMs(),
        ),
      ]);
      await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);

      final outcome = await engines.laptopMedia.continueHere(
        phoneKey('youtube'),
      );

      expect(outcome, isA<ContinueOpened>());
      expect(phoneBackend.commands.single.action, PlayerAction.pause);
      final opened = laptopOpener.opened.single;
      expect(opened.host, 'www.youtube.com');
      expect(opened.queryParameters['v'], 'u7K72X4eo_s');
      final seconds = int.parse(
        opened.queryParameters['t']?.replaceAll('s', '') ?? '0',
      );
      expect(seconds, inInclusiveRange(95, 97));
    },
  );

  test('continue here falls back to the Spotify web player', () async {
    final opener = FakeLinkOpener(refused: {'spotify'});
    await engines.stop();
    phoneBackend = FakeMediaBackend();
    engines = await LinkedEngines.start(
      phoneFeature: MediaFeature(backend: () => phoneBackend),
      laptopFeature: MediaFeature(linkOpener: opener),
    );
    await until(() => phoneBackend.watching);
    phoneBackend.emit([
      playerInfo(
        contentUri: 'spotify:track:4uLU6hMCjMI75M1A2tKUQC',
        positionAtMs: nowMs(),
      ),
    ]);
    await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);

    final outcome = await engines.laptopMedia.continueHere(phoneKey('spotify'));

    expect(outcome, isA<ContinueOpened>());
    expect(opener.attempts.first.scheme, 'spotify');
    expect(
      opener.opened.single.toString(),
      'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC',
    );
  });

  test('continue here resumes the phone when nothing here opens it', () async {
    final opener = FakeLinkOpener(refused: {'https', 'http'});
    await engines.stop();
    phoneBackend = FakeMediaBackend();
    engines = await LinkedEngines.start(
      phoneFeature: MediaFeature(backend: () => phoneBackend),
      laptopFeature: MediaFeature(linkOpener: opener),
    );
    await until(() => phoneBackend.watching);
    phoneBackend.emit([
      playerInfo(
        contentUri: 'https://example.com/podcast/42',
        positionAtMs: nowMs(),
      ),
    ]);
    await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);

    final outcome = await engines.laptopMedia.continueHere(phoneKey('spotify'));
    await until(() => phoneBackend.commands.length == 2);

    expect(outcome, isA<ContinueFailed>());
    expect(phoneBackend.commands.map((command) => command.action), [
      PlayerAction.pause,
      PlayerAction.play,
    ]);
  });

  test('items without a link are not offered for continue', () async {
    phoneBackend.emit([
      playerInfo(appId: 'org.example.player', positionAtMs: nowMs()),
    ]);
    await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);
    final remote = engines.laptopMedia.remotePlayers.single;

    final outcome = await engines.laptopMedia.continueHere(remote.key);

    expect(engines.laptopMedia.continueLinkFor(remote), isNull);
    expect(outcome, isA<ContinueFailed>());
    expect(phoneBackend.commands, isEmpty);
  });

  test('a disconnected device drops off the card', () async {
    phoneBackend.emit([playerInfo(positionAtMs: nowMs())]);
    await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);

    await engines.phone.stop();
    await until(() => engines.laptopMedia.remotePlayers.isEmpty);

    expect(
      engines.laptopMedia.player(phoneKey('spotify'))?.isConnected,
      isFalse,
    );
  });

  test('hiding remote media empties the list', () async {
    phoneBackend.emit([playerInfo(positionAtMs: nowMs())]);
    await until(() => engines.laptopMedia.remotePlayers.isNotEmpty);

    await engines.laptopMedia.setShowRemote(false);
    expect(engines.laptopMedia.remotePlayers, isEmpty);

    await engines.laptopMedia.setShowRemote(true);
    expect(engines.laptopMedia.remotePlayers.single.player.title, 'Teardrop');
  });
}
