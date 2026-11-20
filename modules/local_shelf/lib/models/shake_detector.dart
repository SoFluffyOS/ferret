import 'dart:ui';

import 'package:local_shelf/models/shelf_reach_options.dart';

/// Tells a shake of the pointer from a drag going somewhere: enough quick
/// back-and-forth strokes on one axis, in a short time, without getting
/// far. Measured in points, not events, since the event rate differs by
/// mouse and trackpad.
class ShakeDetector {
  ShakeDetector({this.sensitivity = .normal});

  ShakeSensitivity sensitivity;

  final List<(Duration, Offset)> _samples = [];

  /// Direction changes a shake needs.
  int get reversals => switch (sensitivity) {
    .low => 4,
    .normal => 3,
    .high => 2,
  };

  /// How long each stroke must be, in points.
  double get minStroke => switch (sensitivity) {
    .low => 24,
    .normal => 16,
    .high => 10,
  };

  /// How quickly it must all happen.
  Duration get window => switch (sensitivity) {
    .low => const Duration(milliseconds: 600),
    .normal => const Duration(milliseconds: 500),
    .high => const Duration(milliseconds: 400),
  };

  /// How far it may get from where it started, as a share of the path.
  static const maxNetShare = 0.5;

  /// Wobbles smaller than this don't turn a stroke around.
  static const _jitter = 3.0;

  /// The pointer is at [position] at [time]. True when that made a shake;
  /// it then starts over.
  bool add(Offset position, Duration time) {
    _samples
      ..add((time, position))
      ..removeWhere((sample) => time - sample.$1 > window);
    if (_samples.length < reversals + 2) {
      return false;
    }

    final shook =
        _isShake(_samples.map((sample) => sample.$2.dx)) ||
        _isShake(_samples.map((sample) => sample.$2.dy));
    if (!shook) {
      return false;
    }

    final path = _pathLength();
    final net = (_samples.last.$2 - _samples.first.$2).distance;
    if (path <= 0 || net > path * maxNetShare) {
      return false;
    }

    reset();
    return true;
  }

  void reset() => _samples.clear();

  bool _isShake(Iterable<double> values) {
    final strokes = _strokes(values.toList());
    var run = 0;
    var best = 0;
    for (final stroke in strokes) {
      run = switch (stroke >= minStroke) {
        true => run + 1,
        false => 0,
      };
      if (run > best) {
        best = run;
      }
    }

    return best - 1 >= reversals;
  }

  /// The lengths of the back-and-forth strokes along one axis.
  static List<double> _strokes(List<double> values) {
    final strokes = <double>[];
    var anchor = values.first;
    var extreme = values.first;
    var direction = 0;
    for (final value in values.skip(1)) {
      if (direction == 0) {
        if ((value - anchor).abs() >= _jitter) {
          direction = (value - anchor).sign.toInt();
          extreme = value;
        }

        continue;
      }

      if ((value - extreme) * direction > 0) {
        extreme = value;
        continue;
      }

      if ((value - extreme).abs() >= _jitter) {
        strokes.add((extreme - anchor).abs());
        anchor = extreme;
        extreme = value;
        direction = -direction;
      }
    }

    if (direction != 0) {
      strokes.add((extreme - anchor).abs());
    }

    return strokes;
  }

  double _pathLength() {
    var length = 0.0;
    for (var index = 1; index < _samples.length; index++) {
      length += (_samples[index].$2 - _samples[index - 1].$2).distance;
    }

    return length;
  }
}
