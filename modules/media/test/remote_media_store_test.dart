import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';
import 'package:protocol/media.dart';

MediaState _state({
  required int sentAtMs,
  List<int> artwork = const [],
  String artworkId = 'art-1',
}) => MediaState(
  sentAtMs: Int64(sentAtMs),
  players: [
    MediaPlayer(
      playerId: 'spotify',
      title: 'Teardrop',
      positionMs: Int64(60000),
      positionAtMs: Int64(sentAtMs - 1000),
      lastActiveAtMs: Int64(sentAtMs - 5000),
      durationMs: Int64(330000),
      status: .MEDIA_PLAYBACK_STATUS_PLAYING,
      artworkId: artworkId,
      artwork: artwork,
    ),
  ],
);

void main() {
  group('RemoteMediaStore', () {
    test("maps the sender's clock onto this device's clock", () {
      final store = RemoteMediaStore()
        ..apply(
          deviceId: 'pixel',
          deviceName: 'Pixel',
          state: _state(sentAtMs: 500000),
          nowMs: 800000,
        );

      final player = store.connected.single;
      expect(player.positionAtMs, 799000);
      expect(player.lastActiveAtMs, 795000);
      expect(player.positionAt(800000), 61000);
    });

    test('keeps artwork the device sent once', () {
      final store = RemoteMediaStore()
        ..apply(
          deviceId: 'pixel',
          deviceName: 'Pixel',
          state: _state(sentAtMs: 1000, artwork: [1, 2, 3]),
          nowMs: 1000,
        )
        ..apply(
          deviceId: 'pixel',
          deviceName: 'Pixel',
          state: _state(sentAtMs: 2000),
          nowMs: 2000,
        );

      expect(store.connected.single.artwork, [1, 2, 3]);
      expect(store.connected.single.player.artwork, isEmpty);
    });

    test('keeps the last players of a device that disconnected', () {
      final store = RemoteMediaStore()
        ..apply(
          deviceId: 'pixel',
          deviceName: 'Pixel',
          state: _state(sentAtMs: 1000),
          nowMs: 1000,
        )
        ..markDisconnected('pixel');

      expect(store.connected, isEmpty);
      expect(store.all.single.isConnected, isFalse);
      expect(
        store.find(const PlayerKey('pixel', 'spotify'))?.player.title,
        'Teardrop',
      );
    });
  });
}
