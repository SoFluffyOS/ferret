/// Counts attempts in a sliding window, such as wrong tokens or pairing
/// requests, and says when there were too many.
class AttemptLimiter {
  AttemptLimiter({
    required this.maxAttempts,
    required this.window,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final int maxAttempts;
  final Duration window;
  final DateTime Function() _now;
  final List<DateTime> _attempts = [];

  /// Records an attempt. False when it is one too many; it is not counted
  /// then, so waiting out the window always helps.
  bool tryAcquire() {
    _forgetOld();
    if (_attempts.length >= maxAttempts) {
      return false;
    }

    _attempts.add(_now());
    return true;
  }

  bool get isLimited {
    _forgetOld();
    return _attempts.length >= maxAttempts;
  }

  /// How long until the next attempt is allowed.
  Duration get retryAfter {
    _forgetOld();
    if (_attempts.length < maxAttempts) {
      return Duration.zero;
    }

    return _attempts.first.add(window).difference(_now());
  }

  void _forgetOld() {
    final cutoff = _now().subtract(window);
    _attempts.removeWhere((attempt) => !attempt.isAfter(cutoff));
  }
}
