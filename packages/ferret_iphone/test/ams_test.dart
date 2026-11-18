import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:ferret_iphone/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 18, 12);

  group('Entity Update packets', () {
    test('reads entity, attribute, flags and UTF-8 text', () {
      final update = AmsUpdate.parse(
        Uint8List.fromList([2, 2, 0, ...utf8.encode('Déjà Vu')]),
      );

      expect(update?.entity, AmsEntity.track);
      expect(update?.attribute, AmsTrackAttribute.title);
      expect(update?.isTruncated, isFalse);
      expect(update?.value, 'Déjà Vu');
    });

    test('reads the truncated flag and an empty value', () {
      final update = AmsUpdate.parse(Uint8List.fromList([0, 0, 1]));

      expect(update?.entity, AmsEntity.player);
      expect(update?.isTruncated, isTrue);
      expect(update?.value, '');
    });

    test('rejects short packets and unknown entities', () {
      expect(AmsUpdate.parse(Uint8List.fromList([0, 0])), isNull);
      expect(AmsUpdate.parse(Uint8List.fromList([3, 0, 0, 65])), isNull);
    });
  });

  group('commands', () {
    test('remote command ids follow the specification', () {
      expect(AmsCommand.play.id, 0);
      expect(AmsCommand.pause.id, 1);
      expect(AmsCommand.togglePlayPause.id, 2);
      expect(AmsCommand.nextTrack.id, 3);
      expect(AmsCommand.previousTrack.id, 4);
      expect(AmsCommand.volumeUp.id, 5);
      expect(AmsCommand.volumeDown.id, 6);
      expect(AmsCommand.advanceRepeatMode.id, 7);
      expect(AmsCommand.advanceShuffleMode.id, 8);
      expect(AmsCommand.skipForward.id, 9);
      expect(AmsCommand.skipBackward.id, 10);
      expect(AmsCommand.likeTrack.id, 11);
      expect(AmsCommand.dislikeTrack.id, 12);
      expect(AmsCommand.bookmarkTrack.id, 13);
      expect(AmsCommands.remote(.nextTrack), [3]);
    });

    test('subscriptions list the entity then its attributes', () {
      expect(AmsCommands.subscribe(.player, AmsPlayerAttribute.all), [
        0,
        0,
        1,
        2,
      ]);
      expect(AmsCommands.subscribe(.queue, AmsQueueAttribute.all), [
        1,
        0,
        1,
        2,
        3,
      ]);
      expect(AmsCommands.subscribe(.track, AmsTrackAttribute.all), [
        2,
        0,
        1,
        2,
        3,
      ]);
      expect(AmsCommands.select(.track, AmsTrackAttribute.title), [2, 2]);
    });

    test('reads the supported commands, skipping unknown ids', () {
      expect(AmsCommands.supported(Uint8List.fromList([0, 1, 3, 99])), {
        AmsCommand.play,
        AmsCommand.pause,
        AmsCommand.nextTrack,
      });
    });
  });

  group('state', () {
    AmsState apply(AmsState state, AmsEntity entity, int attribute, String v) =>
        state.apply(
          AmsUpdate(entity: entity, attribute: attribute, value: v),
          now,
        );

    test('collects the track, the player and the queue', () {
      var state = const AmsState();
      state = apply(state, .player, AmsPlayerAttribute.name, 'Music');
      state = apply(state, .player, AmsPlayerAttribute.volume, '0.5');
      state = apply(state, .track, AmsTrackAttribute.title, 'Song');
      state = apply(state, .track, AmsTrackAttribute.artist, 'Artist');
      state = apply(state, .track, AmsTrackAttribute.album, 'Album');
      state = apply(state, .track, AmsTrackAttribute.duration, '185.5');
      state = apply(state, .queue, AmsQueueAttribute.index, '2');
      state = apply(state, .queue, AmsQueueAttribute.count, '12');

      expect(state.playerName, 'Music');
      expect(state.volume, 0.5);
      expect(state.title, 'Song');
      expect(state.artist, 'Artist');
      expect(state.album, 'Album');
      expect(state.duration, const Duration(seconds: 185, milliseconds: 500));
      expect(state.queueIndex, 2);
      expect(state.queueCount, 12);
      expect(state.hasTrack, isTrue);
    });

    test('reads playback info as state, rate and elapsed seconds', () {
      final state = apply(
        const AmsState(),
        .player,
        AmsPlayerAttribute.playbackInfo,
        '1,1.5,12.25',
      );

      expect(state.playback, AmsPlaybackState.playing);
      expect(state.isPlaying, isTrue);
      expect(state.rate, 1.5);
      expect(state.elapsed, const Duration(seconds: 12, milliseconds: 250));
      expect(state.elapsedAt, now);
    });

    test('moves the position on at the playback rate while playing', () {
      var state = apply(
        const AmsState(),
        .track,
        AmsTrackAttribute.duration,
        '100',
      );
      state = apply(
        state,
        .player,
        AmsPlayerAttribute.playbackInfo,
        '1,2.0,10',
      );

      expect(
        state.positionAt(now.add(const Duration(seconds: 5))),
        const Duration(seconds: 20),
      );
      expect(
        state.positionAt(now.add(const Duration(minutes: 5))),
        const Duration(seconds: 100),
      );
    });

    test('holds the position while paused', () {
      final state = apply(
        const AmsState(),
        .player,
        AmsPlayerAttribute.playbackInfo,
        '0,0.0,42',
      );

      expect(
        state.positionAt(now.add(const Duration(minutes: 1))),
        const Duration(seconds: 42),
      );
    });

    test('rewinding moves the position back, never below zero', () {
      final state = apply(
        const AmsState(),
        .player,
        AmsPlayerAttribute.playbackInfo,
        '2,-2.0,10',
      );

      expect(state.playback, AmsPlaybackState.rewinding);
      expect(
        state.positionAt(now.add(const Duration(seconds: 2))),
        const Duration(seconds: 6),
      );
      expect(
        state.positionAt(now.add(const Duration(seconds: 30))),
        Duration.zero,
      );
    });

    test('empty playback info means nothing plays', () {
      var state = apply(
        const AmsState(),
        .player,
        AmsPlayerAttribute.playbackInfo,
        '1,1.0,5',
      );
      state = apply(state, .player, AmsPlayerAttribute.playbackInfo, '');

      expect(state.isPlaying, isFalse);
      expect(state.elapsed, Duration.zero);
      expect(state.elapsedAt, isNull);
    });

    test('a track without duration has none', () {
      var state = apply(
        const AmsState(),
        .track,
        AmsTrackAttribute.duration,
        '200',
      );
      state = apply(state, .track, AmsTrackAttribute.duration, '');

      expect(state.duration, isNull);
    });

    test('every command is worth a try until the iPhone lists its own', () {
      const state = AmsState();
      final limited = state.withSupported({.play, .pause});

      expect(state.supports(.nextTrack), isTrue);
      expect(limited.supports(.play), isTrue);
      expect(limited.supports(.nextTrack), isFalse);
    });
  });

  group('client', () {
    late FakeAppleTransport transport;
    late FakeIphone iphone;
    late AmsClient client;

    setUp(() async {
      transport = FakeAppleTransport();
      iphone = FakeIphone(transport);
      await transport.connect('iphone');
      client = AmsClient(transport, clock: () => now);
      await client.start();
    });

    test('subscribes to commands and to all three entities', () {
      expect(transport.notifying, {
        AppleCharacteristic.remoteCommand,
        AppleCharacteristic.entityUpdate,
      });
      expect(transport.writesTo(.entityUpdate), [
        [0, 0, 1, 2],
        [1, 0, 1, 2, 3],
        [2, 0, 1, 2, 3],
      ]);
    });

    test('follows what plays', () {
      final states = <AmsState>[];
      client.states.listen(states.add);

      iphone.play(title: 'Song', artist: 'Artist', elapsed: 3);

      expect(client.state.title, 'Song');
      expect(client.state.artist, 'Artist');
      expect(client.state.playerName, 'Music');
      expect(client.state.isPlaying, isTrue);
      expect(client.state.elapsed, const Duration(seconds: 3));
      expect(states, isNotEmpty);
    });

    test('sends remote commands', () async {
      await client.send(.togglePlayPause);
      await client.send(.volumeUp);

      expect(iphone.commands, [
        AmsCommand.togglePlayPause,
        AmsCommand.volumeUp,
      ]);
    });

    test('tracks which commands the iPhone accepts', () {
      transport.emit(.remoteCommand, [0, 1, 2]);

      expect(client.state.supports(.togglePlayPause), isTrue);
      expect(client.state.supports(.nextTrack), isFalse);
    });

    test('reads the whole text of a value that was cut short', () async {
      transport.readable[.entityAttribute] = utf8.encode(
        'A very long title that did not fit',
      );

      transport.emit(
        .entityUpdate,
        FakeIphone.updatePacket(
          .track,
          AmsTrackAttribute.title,
          'A very long ti',
          truncated: true,
        ),
      );
      final cutShort = client.state.title;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cutShort, 'A very long ti');
      expect(client.state.title, 'A very long title that did not fit');
      expect(transport.writesTo(.entityAttribute), [
        [2, 2],
      ]);
    });

    test('forgets the track when stopped', () async {
      iphone.play();

      client.stop();

      expect(client.state.hasTrack, isFalse);
    });
  });
}
