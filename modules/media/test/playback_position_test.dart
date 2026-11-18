import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';

void main() {
  group('PlaybackPosition', () {
    test('moves on with the clock while playing', () {
      final position = PlaybackPosition.at(
        nowMs: 10500,
        positionMs: 30000,
        positionAtMs: 10000,
        playing: true,
      );

      expect(position, 30500);
    });

    test('stays put while paused', () {
      final position = PlaybackPosition.at(
        nowMs: 90000,
        positionMs: 30000,
        positionAtMs: 10000,
        playing: false,
      );

      expect(position, 30000);
    });

    test('follows the playback rate', () {
      final position = PlaybackPosition.at(
        nowMs: 12000,
        positionMs: 0,
        positionAtMs: 10000,
        playing: true,
        rate: 1.5,
      );

      expect(position, 3000);
    });

    test('never runs past the end', () {
      final position = PlaybackPosition.at(
        nowMs: 1000000,
        positionMs: 200000,
        positionAtMs: 0,
        playing: true,
        durationMs: 215000,
      );

      expect(position, 215000);
    });

    test('ignores a report from the future', () {
      final position = PlaybackPosition.at(
        nowMs: 1000,
        positionMs: 5000,
        positionAtMs: 4000,
        playing: true,
      );

      expect(position, 5000);
    });
  });
}
