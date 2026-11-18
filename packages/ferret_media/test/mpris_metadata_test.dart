import 'dart:typed_data';

import 'package:dbus/dbus.dart';
import 'package:ferret_media/ferret_media.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, DBusValue> _spotifyProperties({String status = 'Playing'}) => {
  'PlaybackStatus': DBusString(status),
  'Position': const DBusInt64(83 * 1000 * 1000),
  'Rate': const DBusDouble(1),
  'Volume': const DBusDouble(0.5),
  'CanPlay': const DBusBoolean(true),
  'CanPause': const DBusBoolean(true),
  'CanGoNext': const DBusBoolean(true),
  'CanGoPrevious': const DBusBoolean(false),
  'CanSeek': const DBusBoolean(true),
  'Metadata': DBusDict.stringVariant({
    'mpris:trackid': DBusObjectPath('/com/spotify/track/abc'),
    'mpris:length': const DBusUint64(215 * 1000 * 1000),
    'xesam:title': const DBusString('Teardrop'),
    'xesam:artist': DBusArray.string(['Massive Attack', 'Elizabeth Fraser']),
    'xesam:album': const DBusString('Mezzanine'),
    'xesam:url': const DBusString('https://open.spotify.com/track/abc'),
    'mpris:artUrl': const DBusString('https://i.scdn.co/image/xyz'),
  }),
};

void main() {
  group('MprisMetadata', () {
    test('reads a playing track', () {
      final metadata = MprisMetadata(_spotifyProperties());

      expect(metadata.title, 'Teardrop');
      expect(metadata.artist, 'Massive Attack, Elizabeth Fraser');
      expect(metadata.album, 'Mezzanine');
      expect(metadata.durationMs, 215000);
      expect(metadata.positionMs, 83000);
      expect(metadata.status, PlayerStatus.playing);
      expect(metadata.trackId, '/com/spotify/track/abc');
      expect(metadata.contentUri, 'https://open.spotify.com/track/abc');
      expect(metadata.volume, 0.5);
    });

    test('lists only the actions the player allows', () {
      final metadata = MprisMetadata(_spotifyProperties());

      expect(metadata.actions, [
        PlayerAction.play,
        PlayerAction.pause,
        PlayerAction.toggle,
        PlayerAction.next,
        PlayerAction.seek,
        PlayerAction.setVolume,
      ]);
    });

    test('keeps local file paths private', () {
      final properties = _spotifyProperties()
        ..['Metadata'] = DBusDict.stringVariant({
          'xesam:title': const DBusString('Home video'),
          'xesam:url': const DBusString('file:///home/me/video.mp4'),
        });

      expect(MprisMetadata(properties).contentUri, isNull);
    });

    test('builds a player, but not for a stopped one', () {
      final playing = MprisMetadata(_spotifyProperties()).toPlayer(
        busName: 'org.mpris.MediaPlayer2.spotify',
        appName: 'Spotify',
        appId: 'spotify',
        nowMs: 1000,
        lastActiveAtMs: 900,
      );
      final stopped =
          MprisMetadata(
            _spotifyProperties(status: 'Stopped'),
          ).toPlayer(
            busName: 'org.mpris.MediaPlayer2.spotify',
            appName: 'Spotify',
            appId: 'spotify',
            nowMs: 1000,
            lastActiveAtMs: 900,
          );

      expect(playing?.id, 'org.mpris.MediaPlayer2.spotify');
      expect(playing?.positionAtMs, 1000);
      expect(playing?.lastActiveAtMs, 900);
      expect(stopped, isNull);
    });
  });

  group('ArtworkShrinker', () {
    test('keeps a small JPEG as it is', () async {
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);

      expect(await ArtworkShrinker.shrink(jpeg), same(jpeg));
    });

    test('gives up on bytes that are not an image', () async {
      final junk = Uint8List.fromList(List.filled(10, 7));

      expect(await ArtworkShrinker.shrink(junk), isNull);
    });
  });

  test('the unsupported backend reports it', () async {
    const backend = UnsupportedMediaBackend();

    expect(await backend.access(), MediaAccess.unsupported);
    expect(await backend.currentPlayers(), isEmpty);
    expect(await backend.command('x', PlayerAction.play), isFalse);
  });
}
