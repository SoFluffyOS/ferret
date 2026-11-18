import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';

ContinueLink? _link(
  String contentUri, {
  int positionMs = 83000,
  String appId = 'org.example.player',
}) => ContinueLinks.build(
  contentUri: contentUri,
  appId: appId,
  title: 'Teardrop',
  artist: 'Massive Attack',
  positionMs: positionMs,
);

void main() {
  group('ContinueLinks', () {
    test('YouTube links get t= in seconds', () {
      final link = _link('https://www.youtube.com/watch?v=u7K72X4eo_s');

      expect(
        link?.candidates.single.toString(),
        'https://www.youtube.com/watch?v=u7K72X4eo_s&t=83s',
      );
      expect(link?.keepsPosition, isTrue);
    });

    test('an old t= is replaced, and youtu.be works too', () {
      final link = _link('https://youtu.be/u7K72X4eo_s?t=10');

      expect(
        link?.candidates.single.toString(),
        'https://youtu.be/u7K72X4eo_s?t=83s',
      );
    });

    test('YouTube at the start has no t=', () {
      final link = _link('https://youtu.be/u7K72X4eo_s?t=10', positionMs: 400);

      expect(
        link?.candidates.single.toString(),
        'https://youtu.be/u7K72X4eo_s',
      );
      expect(link?.keepsPosition, isFalse);
    });

    test('Spotify URIs get the position as #m:ss', () {
      final link = _link('spotify:track:4uLU6hMCjMI75M1A2tKUQC');

      expect(link?.candidates.map((uri) => uri.toString()), [
        'spotify:track:4uLU6hMCjMI75M1A2tKUQC#1:23',
        'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC',
      ]);
      expect(link?.keepsPosition, isTrue);
    });

    test('Spotify web links open in the app first, then on the web', () {
      final link = _link(
        'https://open.spotify.com/intl-de/episode/abc123?si=xyz',
      );

      expect(link?.candidates.first.toString(), 'spotify:episode:abc123#1:23');
      expect(
        link?.candidates.last.toString(),
        'https://open.spotify.com/intl-de/episode/abc123',
      );
    });

    test('Spotify playlists open without a position', () {
      final link = _link('spotify:playlist:37i9dQZF1DXcBWIGoYBM5M');

      expect(
        link?.candidates.first.toString(),
        'spotify:playlist:37i9dQZF1DXcBWIGoYBM5M',
      );
      expect(link?.keepsPosition, isFalse);
    });

    test('Vimeo and SoundCloud use a fragment', () {
      expect(
        _link('https://vimeo.com/76979871')?.candidates.single.toString(),
        'https://vimeo.com/76979871#t=83s',
      );
      expect(
        _link(
          'https://soundcloud.com/artist/track',
        )?.candidates.single.toString(),
        'https://soundcloud.com/artist/track#t=1:23',
      );
    });

    test('Twitch videos get t= in hours, minutes and seconds', () {
      final link = _link(
        'https://www.twitch.tv/videos/123',
        positionMs: 3723000,
      );

      expect(
        link?.candidates.single.toString(),
        'https://www.twitch.tv/videos/123?t=1h2m3s',
      );
    });

    test('other web links open as they are', () {
      final link = _link('https://example.com/podcast/42');

      expect(
        link?.candidates.single.toString(),
        'https://example.com/podcast/42',
      );
      expect(link?.keepsPosition, isFalse);
    });

    test('local files and unknown schemes are not opened', () {
      expect(_link('file:///home/me/song.mp3'), isNull);
      expect(_link('content://media/external/audio/1'), isNull);
    });

    test('without a link, Spotify and YouTube search for the item', () {
      final spotify = _link('', appId: 'com.spotify.music');
      final youTube = _link('', appId: 'com.google.android.youtube');

      expect(
        spotify?.candidates.first.toString(),
        'spotify:search:Teardrop%20Massive%20Attack',
      );
      expect(
        youTube?.candidates.single.toString(),
        'https://www.youtube.com/results?search_query=Teardrop+Massive+Attack',
      );
      expect(spotify?.keepsPosition, isFalse);
    });

    test('without a link, other apps have nothing to open', () {
      expect(_link(''), isNull);
    });
  });
}
