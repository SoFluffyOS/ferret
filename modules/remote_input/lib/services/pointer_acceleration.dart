import 'dart:math';

/// Makes a slow finger precise and a fast flick cross the screen, like a
/// laptop touchpad: the gain grows with the finger's speed, up to a limit.
class PointerAcceleration {
  const PointerAcceleration({this.speed = 1.0});

  /// Below this speed, in logical pixels per millisecond, the pointer moves
  /// one to one (times [speed]).
  static const slowSpeed = 0.2;

  /// The most a fast flick is boosted.
  static const maxBoost = 3.0;

  /// How fast the boost grows with speed past [slowSpeed].
  static const _growth = 1.5;

  /// The person's setting, 1 for normal.
  final double speed;

  /// The pointer distance for a finger move of [dx], [dy] over [elapsed].
  (double, double) apply(double dx, double dy, Duration elapsed) {
    final milliseconds = max(elapsed.inMicroseconds / 1000, 1.0);
    final velocity = sqrt(dx * dx + dy * dy) / milliseconds;
    final boost = min(1 + max(velocity - slowSpeed, 0) * _growth, maxBoost);
    final gain = speed * boost;
    return (dx * gain, dy * gain);
  }
}
