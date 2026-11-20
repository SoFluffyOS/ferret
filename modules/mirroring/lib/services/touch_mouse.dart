import 'dart:async';
import 'dart:ui';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:mirroring/services/mirror_protocol.dart';

/// Turns fingers on a touch screen into a computer's mouse, for a phone
/// or tablet that is that computer's display: a tap clicks, a drag holds
/// the button down while it moves, holding still right-clicks, and two
/// fingers scroll with the content following them. The pointer jumps to
/// where a finger lands, so it shows before anything is pressed.
///
/// Positions are in the picture's own space, [size] its size; what goes
/// out is in fractions of it.
class TouchMouse {
  TouchMouse({
    required void Function(MirrorPointer pointer) send,
    this.pointsPerPixel = 1,
    this.holdTime = const Duration(milliseconds: 500),
    this.slop = 8,
    this.onHeld,
  }) : _send = send;

  /// Points of the computer's display per pixel the fingers move on the
  /// picture, so a scroll goes as far as the fingers.
  double pointsPerPixel;

  /// How long a finger holds still for a right-click.
  final Duration holdTime;

  /// How far a finger moves, in pixels, before it is a drag and not a tap.
  final double slop;

  /// A hold turned into a right-click: a good moment for a small buzz.
  final void Function()? onHeld;

  final void Function(MirrorPointer pointer) _send;
  final Map<int, Offset> _fingers = {};
  _Gesture _gesture = .idle;
  int? _first;
  Offset _start = Offset.zero;
  Size _size = Size.zero;
  Offset? _scrollFrom;
  Timer? _hold;

  static const _primary = 0x01;
  static const _secondary = 0x02;

  void down(int pointer, Offset position, Size size) {
    _size = size;
    _fingers[pointer] = position;
    switch (_gesture) {
      case .idle:
        _first = pointer;
        _start = position;
        _gesture = .pending;
        _point(.hover, position, buttons: 0);
        _hold?.cancel();
        _hold = Timer(holdTime, _onHold);
      case .pending:
        _hold?.cancel();
        _gesture = .scrolling;
        _scrollFrom = _middle();
      case .dragging || .scrolling || .held:
        break;
    }
  }

  void move(int pointer, Offset position, Size size) {
    if (!_fingers.containsKey(pointer)) {
      return;
    }

    _size = size;
    _fingers[pointer] = position;
    switch (_gesture) {
      case .pending when pointer == _first:
        if ((position - _start).distance < slop) {
          return;
        }

        _hold?.cancel();
        _gesture = .dragging;
        _point(.down, _start, buttons: _primary);
        _point(.move, position, buttons: _primary);
      case .dragging when pointer == _first:
        _point(.move, position, buttons: _primary);
      case .scrolling:
        _scroll();
      case .idle || .pending || .dragging || .held:
        break;
    }
  }

  void up(int pointer, Offset position, Size size) {
    if (!_fingers.containsKey(pointer)) {
      return;
    }

    _size = size;
    _fingers[pointer] = position;
    switch (_gesture) {
      case .pending when pointer == _first:
        _hold?.cancel();
        _point(.down, _start, buttons: _primary);
        _point(.up, _start, buttons: _primary);
        _gesture = .held;
      case .dragging when pointer == _first:
        _point(.up, position, buttons: _primary);
        _gesture = .held;
      case .scrolling:
        _scroll();
      case .idle || .pending || .dragging || .held:
        break;
    }

    _lift(pointer);
  }

  /// The system took the finger away: a press it held lets go.
  void cancel(int pointer) {
    if (!_fingers.containsKey(pointer)) {
      return;
    }

    if (_gesture == .dragging && pointer == _first) {
      _point(.up, _fingers[pointer] ?? _start, buttons: _primary);
      _gesture = .held;
    }

    if (_gesture == .pending && pointer == _first) {
      _hold?.cancel();
      _gesture = .held;
    }

    _lift(pointer);
  }

  void dispose() {
    _hold?.cancel();
    _hold = null;
  }

  void _lift(int pointer) {
    _fingers.remove(pointer);
    if (_gesture == .scrolling) {
      _scrollFrom = _middle();
    }

    if (_fingers.isEmpty) {
      _gesture = .idle;
      _first = null;
      _scrollFrom = null;
    }
  }

  void _onHold() {
    if (_gesture != .pending) {
      return;
    }

    _gesture = .held;
    _point(.down, _start, buttons: _secondary);
    _point(.up, _start, buttons: _secondary);
    onHeld?.call();
  }

  void _scroll() {
    final middle = _middle();
    final from = _scrollFrom;
    _scrollFrom = middle;
    if (middle == null || from == null) {
      return;
    }

    final moved = middle - from;
    if (moved == Offset.zero) {
      return;
    }

    // The content follows the fingers, so it scrolls the other way.
    final notches = -moved * pointsPerPixel / MirrorProtocol.pointsPerNotch;
    _send(
      MirrorPointer(
        phase: .scroll,
        x: _fraction(middle.dx, _size.width),
        y: _fraction(middle.dy, _size.height),
        buttons: 0,
        scrollX: notches.dx,
        scrollY: notches.dy,
      ),
    );
  }

  Offset? _middle() {
    if (_fingers.isEmpty) {
      return null;
    }

    var sum = Offset.zero;
    for (final position in _fingers.values) {
      sum += position;
    }

    return sum / _fingers.length.toDouble();
  }

  void _point(PointerPhase phase, Offset position, {required int buttons}) =>
      _send(
        MirrorPointer(
          phase: phase,
          x: _fraction(position.dx, _size.width),
          y: _fraction(position.dy, _size.height),
          buttons: buttons,
        ),
      );

  static double _fraction(double position, double length) {
    if (length <= 0) {
      return 0;
    }

    return (position / length).clamp(0.0, 1.0);
  }
}

enum _Gesture {
  idle,

  /// One finger is down and hasn't said what it does yet.
  pending,
  dragging,
  scrolling,

  /// It clicked or right-clicked: the rest waits for every finger to lift.
  held,
}
