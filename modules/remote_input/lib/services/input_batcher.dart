import 'dart:async';

import 'package:protocol/remote_input.dart';
import 'package:remote_input/services/input_codec.dart';

/// Gathers the controller's input into batches: pointer moves and scrolls
/// add up and leave at most once per [interval]; clicks and keys leave right
/// away, after the motion that came before them. No reply is expected, so
/// a fast finger never waits on the network.
class InputBatcher {
  InputBatcher({
    required void Function(List<InputEvent> events) send,
    this.interval = const Duration(milliseconds: 16),
    DateTime Function()? clock,
  }) : _send = send,
       _clock = clock ?? DateTime.now;

  final Duration interval;
  final void Function(List<InputEvent> events) _send;
  final DateTime Function() _clock;
  final List<InputEvent> _discrete = [];

  double _moveX = 0;
  double _moveY = 0;
  double _scrollX = 0;
  double _scrollY = 0;
  DateTime? _lastSent;
  Timer? _timer;
  bool _disposed = false;

  /// Moves by a distance in logical pixels; fractions carry over.
  void move(double dx, double dy) {
    _moveX += dx;
    _moveY += dy;
    _schedule();
  }

  /// Scrolls by a distance in logical pixels; fractions carry over.
  void scroll(double dx, double dy) {
    _scrollX += dx;
    _scrollY += dy;
    _schedule();
  }

  /// A click, key or text: sent now, after any motion waiting.
  void add(InputEvent event) {
    if (_disposed) {
      return;
    }

    _discrete.add(event);
    flush();
  }

  /// Sends whatever is waiting.
  void flush() {
    _timer?.cancel();
    _timer = null;
    if (_disposed) {
      return;
    }

    final moveX = _moveX.truncate();
    final moveY = _moveY.truncate();
    final scrollX = _scrollX.truncate();
    final scrollY = _scrollY.truncate();
    _moveX -= moveX;
    _moveY -= moveY;
    _scrollX -= scrollX;
    _scrollY -= scrollY;

    final events = [
      if (moveX != 0 || moveY != 0) InputCodec.move(moveX, moveY),
      if (scrollX != 0 || scrollY != 0) InputCodec.scroll(scrollX, scrollY),
      ..._discrete,
    ];
    _discrete.clear();
    if (events.isEmpty) {
      return;
    }

    _lastSent = _clock();
    _send(events);
  }

  /// Drops anything waiting and stops sending.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _discrete.clear();
  }

  void _schedule() {
    if (_disposed || _timer != null) {
      return;
    }

    final lastSent = _lastSent;
    final elapsed = switch (lastSent) {
      final sent? => _clock().difference(sent),
      null => interval,
    };
    if (elapsed >= interval) {
      flush();
      return;
    }

    _timer = Timer(interval - elapsed, flush);
  }
}
