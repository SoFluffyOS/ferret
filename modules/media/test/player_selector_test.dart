import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';
import 'package:protocol/media.dart';

RemotePlayer _remote(
  String id, {
  bool playing = true,
  int lastActiveAtMs = 0,
  String deviceId = 'pixel',
}) => RemotePlayer(
  deviceId: deviceId,
  deviceName: 'Pixel',
  player: MediaPlayer(
    playerId: id,
    status: switch (playing) {
      true => .MEDIA_PLAYBACK_STATUS_PLAYING,
      false => .MEDIA_PLAYBACK_STATUS_PAUSED,
    },
    durationMs: Int64(1000),
  ),
  positionAtMs: 0,
  lastActiveAtMs: lastActiveAtMs,
);

void main() {
  group('PlayerSelector', () {
    test('picks nothing when nothing plays', () {
      expect(PlayerSelector.select(const []), isNull);
    });

    test('prefers a playing player over a paused one', () {
      final paused = _remote('podcast', playing: false, lastActiveAtMs: 900);
      final playing = _remote('spotify', lastActiveAtMs: 100);

      expect(PlayerSelector.select([paused, playing]), same(playing));
    });

    test('follows the last active player', () {
      final older = _remote('spotify', lastActiveAtMs: 100);
      final newer = _remote('youtube', lastActiveAtMs: 500);

      expect(PlayerSelector.select([older, newer]), same(newer));
    });

    test('keeps the picked player', () {
      final picked = _remote('spotify', lastActiveAtMs: 100);
      final other = _remote('youtube', lastActiveAtMs: 500);

      final selected = PlayerSelector.select([
        picked,
        other,
      ], pick: PlayerPick(picked.key, 1000));

      expect(selected, same(picked));
    });

    test('a player that starts after the pick takes over', () {
      final picked = _remote('spotify', lastActiveAtMs: 100);
      final started = _remote('youtube', lastActiveAtMs: 2000);

      final selected = PlayerSelector.select([
        picked,
        started,
      ], pick: PlayerPick(picked.key, 1000));

      expect(selected, same(started));
    });

    test('falls back when the picked player is gone', () {
      final remaining = _remote('youtube', lastActiveAtMs: 100);

      final selected = PlayerSelector.select([
        remaining,
      ], pick: const PlayerPick(PlayerKey('pixel', 'spotify'), 1000));

      expect(selected, same(remaining));
    });
  });
}
