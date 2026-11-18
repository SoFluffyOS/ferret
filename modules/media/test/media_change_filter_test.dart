import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';
import 'package:protocol/media.dart';

MediaPlayer _player({
  int positionMs = 60000,
  int positionAtMs = 1000000,
  MediaPlaybackStatus status = .MEDIA_PLAYBACK_STATUS_PLAYING,
  String title = 'Teardrop',
}) => MediaPlayer(
  playerId: 'spotify',
  title: title,
  positionMs: Int64(positionMs),
  positionAtMs: Int64(positionAtMs),
  durationMs: Int64(330000),
  status: status,
  playbackRate: 1,
);

void main() {
  group('MediaChangeFilter', () {
    test('a position that moved with the clock is not worth sending', () {
      final before = [_player()];
      final after = [_player(positionMs: 70000, positionAtMs: 1010000)];

      expect(MediaChangeFilter.isSignificant(before, after), isFalse);
    });

    test('small jitter is not worth sending', () {
      final before = [_player()];
      final after = [_player(positionMs: 71500, positionAtMs: 1010000)];

      expect(MediaChangeFilter.isSignificant(before, after), isFalse);
    });

    test('a seek is worth sending', () {
      final before = [_player()];
      final after = [_player(positionMs: 200000, positionAtMs: 1010000)];

      expect(MediaChangeFilter.isSignificant(before, after), isTrue);
    });

    test('pausing and a new track are worth sending', () {
      final before = [_player()];

      expect(
        MediaChangeFilter.isSignificant(before, [
          _player(status: .MEDIA_PLAYBACK_STATUS_PAUSED),
        ]),
        isTrue,
      );
      expect(
        MediaChangeFilter.isSignificant(before, [_player(title: 'Angel')]),
        isTrue,
      );
    });

    test('a player coming or going is worth sending', () {
      expect(MediaChangeFilter.isSignificant([], [_player()]), isTrue);
      expect(MediaChangeFilter.isSignificant([_player()], []), isTrue);
    });
  });
}
