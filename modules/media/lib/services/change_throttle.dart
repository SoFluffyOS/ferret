import 'dart:async';

/// Sends at most one value per [interval]: the first right away, then the
/// latest one when the interval ends. Values in between are dropped.
class ChangeThrottle<T> {
  ChangeThrottle({required this.interval, required this.onSend});

  final Duration interval;
  final void Function(T value) onSend;

  Timer? _cooldown;
  T? _pending;
  bool _hasPending = false;

  void push(T value) {
    if (_cooldown != null) {
      _pending = value;
      _hasPending = true;
      return;
    }

    _send(value);
  }

  void cancel() {
    _cooldown?.cancel();
    _cooldown = null;
    _pending = null;
    _hasPending = false;
  }

  void _send(T value) {
    onSend(value);
    _cooldown = Timer(interval, _onCooldownEnd);
  }

  void _onCooldownEnd() {
    _cooldown = null;
    if (!_hasPending) {
      return;
    }

    final value = _pending as T;
    _pending = null;
    _hasPending = false;
    _send(value);
  }
}
