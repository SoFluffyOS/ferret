import 'package:flutter_test/flutter_test.dart';
import 'package:local_shelf/local_shelf.dart';

/// Pointer samples every 8 ms, as a mouse reports them: [strokes] runs of
/// [length] points back and forth along x (or y), each taking [each].
List<(Duration, Offset)> zigzag({
  required int strokes,
  required double length,
  Duration each = const Duration(milliseconds: 80),
  bool vertical = false,
  Offset drift = Offset.zero,
  Offset start = const Offset(600, 400),
}) {
  const step = Duration(milliseconds: 8);
  final samples = <(Duration, Offset)>[];
  final perStroke = each.inMilliseconds ~/ step.inMilliseconds;
  final total = strokes * perStroke;
  var along = 0.0;
  var direction = 1.0;
  for (var index = 0; index <= total; index++) {
    if (index > 0) {
      along += direction * length / perStroke;
      if (index % perStroke == 0) {
        direction = -direction;
      }
    }

    final wobble = switch (vertical) {
      true => Offset(0, along),
      false => Offset(along, 0),
    };
    samples.add((step * index, start + wobble + drift * (index / total)));
  }

  return samples;
}

/// Feeds [samples] and says whether any of them made a shake.
bool shakes(ShakeDetector detector, List<(Duration, Offset)> samples) {
  var shook = false;
  for (final (time, position) in samples) {
    shook = detector.add(position, time) || shook;
  }

  return shook;
}

void main() {
  test('four quick 24 pt strokes are a shake at Normal', () {
    expect(shakes(ShakeDetector(), zigzag(strokes: 4, length: 24)), isTrue);
  });

  test('up and down counts the same as side to side', () {
    expect(
      shakes(ShakeDetector(), zigzag(strokes: 4, length: 24, vertical: true)),
      isTrue,
    );
  });

  test('a straight drag across the screen is no shake', () {
    final samples = [
      for (var index = 0; index < 60; index++)
        (Duration(milliseconds: 8 * index), Offset(100 + index * 10.0, 400)),
    ];

    expect(shakes(ShakeDetector(), samples), isFalse);
  });

  test('back and forth spread over seconds is no shake', () {
    final samples = zigzag(
      strokes: 6,
      length: 40,
      each: const Duration(milliseconds: 400),
    );

    expect(shakes(ShakeDetector(), samples), isFalse);
  });

  test('a fling with a wobble on the way is no shake', () {
    final samples = zigzag(
      strokes: 4,
      length: 20,
      vertical: true,
      drift: const Offset(400, 0),
    );

    expect(shakes(ShakeDetector(), samples), isFalse);
  });

  test('High takes smaller strokes than Normal', () {
    final small = zigzag(strokes: 4, length: 12);

    expect(shakes(ShakeDetector(), small), isFalse);
    expect(shakes(ShakeDetector(sensitivity: .high), small), isTrue);
  });

  test('Low takes more and bigger strokes', () {
    expect(
      shakes(
        ShakeDetector(sensitivity: .low),
        zigzag(strokes: 4, length: 24),
      ),
      isFalse,
    );
    expect(
      shakes(
        ShakeDetector(sensitivity: .low),
        zigzag(strokes: 5, length: 30, each: const Duration(milliseconds: 96)),
      ),
      isTrue,
    );
  });

  test('a shake starts over once it counted', () {
    final detector = ShakeDetector();
    final samples = zigzag(strokes: 4, length: 24);
    var count = 0;
    for (final (time, position) in samples) {
      if (detector.add(position, time)) {
        count++;
      }
    }

    expect(count, 1);
  });
}
