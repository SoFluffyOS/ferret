/// Lets progress through at most once per [interval], so a fast transfer
/// doesn't rebuild the UI for every chunk.
class ProgressThrottle {
  ProgressThrottle({this.interval = const Duration(milliseconds: 120)});

  final Duration interval;
  final Stopwatch _clock = Stopwatch()..start();
  Duration? _last;

  bool get shouldEmit {
    final now = _clock.elapsed;
    if (_last case final last? when now - last < interval) {
      return false;
    }

    _last = now;
    return true;
  }
}
