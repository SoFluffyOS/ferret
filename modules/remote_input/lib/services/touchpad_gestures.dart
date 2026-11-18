import 'dart:async';
import 'dart:ui';

import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:remote_input/services/scroll_momentum.dart';

/// Where [TouchpadGestures] sends what the fingers meant.
abstract interface class TouchpadSink {
  /// One finger moved by [dx], [dy] over [elapsed] since its last move.
  void move(double dx, double dy, Duration elapsed);

  /// Two fingers moved by [dx], [dy] together.
  void scroll(double dx, double dy);

  void click(PointerButton button);

  void press(PointerButton button);

  void release(PointerButton button);
}

/// Reads touches on the touchpad the way a laptop touchpad does: one finger
/// moves, a tap clicks, two fingers scroll, a two-finger tap or a long press
/// right-clicks, and tap-then-slide drags. A two-finger flick keeps
/// scrolling the computer for a moment after the fingers lift.
class TouchpadGestures {
  TouchpadGestures(
    this._sink, {
    this.longPress = const Duration(milliseconds: 500),
    this.tapTimeout = const Duration(milliseconds: 250),
    this.dragWindow = const Duration(milliseconds: 300),
    this.slop = 8,
  }) {
    _momentum = ScrollMomentum(_sink.scroll);
  }

  final Duration longPress;

  /// A touch longer than this is not a tap.
  final Duration tapTimeout;

  /// A touch this soon after a tap starts a drag when it moves.
  final Duration dragWindow;

  /// Travel, in logical pixels, under which a touch still counts as a tap.
  final double slop;

  final TouchpadSink _sink;
  late final ScrollMomentum _momentum;
  final Map<int, Offset> _fingers = {};
  final Map<int, Duration> _lastMoveAt = {};

  Duration _startedAt = Duration.zero;
  int _maxFingers = 0;
  double _travel = 0;
  bool _dragArmed = false;
  bool _dragging = false;
  bool _longPressed = false;
  Duration? _lastTapAt;
  Timer? _longPressTimer;

  bool get isDragging => _dragging;

  bool get isGliding => _momentum.isGliding;

  void down(int pointer, Offset position, Duration time) {
    _momentum.stop();
    if (_fingers.isEmpty) {
      _start(time);
    }

    _fingers[pointer] = position;
    _lastMoveAt[pointer] = time;
    if (_fingers.length > _maxFingers) {
      _maxFingers = _fingers.length;
    }

    if (_fingers.length > 1) {
      _cancelLongPress();
    }
  }

  void moveTo(int pointer, Offset position, Duration time) {
    final previous = _fingers[pointer];
    if (previous == null) {
      return;
    }

    final delta = position - previous;
    final elapsed = time - (_lastMoveAt[pointer] ?? time);
    _fingers[pointer] = position;
    _lastMoveAt[pointer] = time;
    _travel += delta.distance;
    if (_travel >= slop) {
      _cancelLongPress();
    }

    if (_maxFingers == 1) {
      _moveOne(delta, elapsed);
      return;
    }

    if (_fingers.length == 2) {
      final share = delta / _fingers.length.toDouble();
      _momentum.track(share, time);
      _sink.scroll(share.dx, share.dy);
    }
  }

  void up(int pointer, Duration time) {
    if (_fingers.remove(pointer) == null) {
      return;
    }

    _lastMoveAt.remove(pointer);
    if (_fingers.length == 1 && _maxFingers == 2) {
      _momentum.release(time);
    }

    if (_fingers.isNotEmpty) {
      return;
    }

    _end(time);
  }

  /// The system took the touch away, such as for a notification shade.
  void cancel(int pointer) {
    _momentum.stop();
    _fingers.remove(pointer);
    _lastMoveAt.remove(pointer);
    if (_fingers.isNotEmpty) {
      return;
    }

    _cancelLongPress();
    if (_dragging) {
      _dragging = false;
      _sink.release(.left);
    }

    _lastTapAt = null;
  }

  void dispose() {
    _momentum.stop();
    _cancelLongPress();
    if (_dragging) {
      _dragging = false;
      _sink.release(.left);
    }
  }

  void _start(Duration time) {
    final lastTapAt = _lastTapAt;
    _startedAt = time;
    _maxFingers = 0;
    _travel = 0;
    _longPressed = false;
    _dragging = false;
    _dragArmed = lastTapAt != null && time - lastTapAt <= dragWindow;
    _longPressTimer = Timer(longPress, _onLongPress);
  }

  void _moveOne(Offset delta, Duration elapsed) {
    if (_dragArmed && !_dragging && _travel >= slop) {
      _dragging = true;
      _sink.press(.left);
    }

    _sink.move(delta.dx, delta.dy, elapsed);
  }

  void _end(Duration time) {
    _cancelLongPress();
    final quick = time - _startedAt <= tapTimeout;
    final still = _travel < slop;

    if (_dragging) {
      _dragging = false;
      _lastTapAt = null;
      _sink.release(.left);
      return;
    }

    if (_longPressed || !quick || !still) {
      _lastTapAt = null;
      return;
    }

    if (_maxFingers == 1) {
      _lastTapAt = time;
      _sink.click(.left);
      return;
    }

    _lastTapAt = null;
    if (_maxFingers == 2) {
      _sink.click(.right);
    }
  }

  /// Holding still: a right click, or the start of a drag right after a
  /// tap.
  void _onLongPress() {
    _longPressTimer = null;
    if (_fingers.length != 1 || _maxFingers != 1 || _travel >= slop) {
      return;
    }

    if (_dragArmed) {
      _dragging = true;
      _sink.press(.left);
      return;
    }

    _longPressed = true;
    _sink.click(.right);
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }
}
