import 'dart:async';
import 'dart:math';
import 'dart:ui';

/// Keeps a two-finger scroll going after the fingers lift, slowing down
/// like a laptop touchpad's, so the page on the computer glides instead of
/// stopping dead. The phone's own screen never moves.
class ScrollMomentum {
  ScrollMomentum(
    this._emit, {
    this.frame = const Duration(milliseconds: 16),
    this.friction = 0.94,
    this.minSpeed = 0.3,
    this.stopSpeed = 0.02,
    this.window = const Duration(milliseconds: 100),
  });

  /// How often a gliding scroll sends a step.
  final Duration frame;

  /// The share of the speed kept after each [frame].
  final double friction;

  /// A lift slower than this, in logical pixels per millisecond, just stops.
  final double minSpeed;

  /// The glide ends below this speed.
  final double stopSpeed;

  /// Only the moves this recent count toward the speed at lift.
  final Duration window;

  final void Function(double dx, double dy) _emit;
  final List<(Duration, Offset)> _samples = [];
  Timer? _timer;
  Offset _velocity = Offset.zero;

  bool get isGliding => _timer != null;

  /// The fingers scrolled by [delta] at [time].
  void track(Offset delta, Duration time) {
    _samples
      ..add((time, delta))
      ..removeWhere((sample) => time - sample.$1 > window);
  }

  /// The fingers lifted at [time]: glide on if they were still moving fast.
  void release(Duration time) {
    final velocity = _velocityAt(time);
    _samples.clear();
    if (velocity.distance < minSpeed) {
      return;
    }

    _velocity = velocity;
    _timer?.cancel();
    _timer = Timer.periodic(frame, (_) => _step());
  }

  /// A finger touched down, or control ended: the glide stops at once.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _samples.clear();
  }

  Offset _velocityAt(Duration time) {
    final recent = [
      for (final sample in _samples)
        if (time - sample.$1 <= window) sample,
    ];
    if (recent.length < 2) {
      return Offset.zero;
    }

    final span = recent.last.$1 - recent.first.$1;
    final milliseconds = max(span.inMicroseconds / 1000, 1.0);
    final distance = recent
        .skip(1)
        .fold(Offset.zero, (sum, sample) => sum + sample.$2);
    return distance / milliseconds;
  }

  void _step() {
    final milliseconds = frame.inMicroseconds / 1000;
    final step = _velocity * milliseconds;
    _emit(step.dx, step.dy);

    _velocity = _velocity * friction;
    if (_velocity.distance < stopSpeed) {
      stop();
    }
  }
}
