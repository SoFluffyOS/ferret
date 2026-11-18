import 'package:flutter_test/flutter_test.dart';
import 'package:remote_input/remote_input.dart';

void main() {
  group('text diff', () {
    test('typing adds text', () {
      expect(TextDiff.between('he', 'hello'), (deleted: 0, inserted: 'llo'));
    });

    test('deleting at the end is backspace', () {
      expect(TextDiff.between('hello', 'hel'), (deleted: 2, inserted: ''));
    });

    test('an autocorrected word deletes back and types it again', () {
      expect(
        TextDiff.between('teh ', 'the '),
        (deleted: 3, inserted: 'he '),
      );
    });

    test('emoji count as one character', () {
      expect(TextDiff.between('a🦊', 'a'), (deleted: 1, inserted: ''));
    });
  });

  group('pointer acceleration', () {
    test('a slow finger moves one to one', () {
      const acceleration = PointerAcceleration();

      expect(
        acceleration.apply(2, 0, const Duration(milliseconds: 16)),
        (2.0, 0.0),
      );
    });

    test('a fast flick goes further, up to a limit', () {
      const acceleration = PointerAcceleration();

      final (fast, _) = acceleration.apply(
        40,
        0,
        const Duration(milliseconds: 16),
      );
      final (fastest, _) = acceleration.apply(
        400,
        0,
        const Duration(milliseconds: 16),
      );

      expect(fast, greaterThan(40));
      expect(fastest, 400 * PointerAcceleration.maxBoost);
    });

    test('the speed setting scales everything', () {
      expect(
        const PointerAcceleration(
          speed: 2,
        ).apply(1, 1, const Duration(milliseconds: 16)),
        (2.0, 2.0),
      );
    });
  });
}
