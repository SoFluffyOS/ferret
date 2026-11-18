/// Measures recent throughput over a short sliding window, so speed and ETA
/// follow the network instead of the average since the start.
class SpeedMeter {
  SpeedMeter({
    this.window = const Duration(seconds: 3),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration window;
  final DateTime Function() _clock;
  final List<(DateTime, int)> _samples = [];

  /// Records that [totalBytes] are done by now.
  void add(int totalBytes) {
    final now = _clock();
    _samples.add((now, totalBytes));
    final oldest = now.subtract(window);
    while (_samples.length > 2 && _samples.first.$1.isBefore(oldest)) {
      _samples.removeAt(0);
    }
  }

  void reset() => _samples.clear();

  /// Bytes per second over the window, or 0 before there are two samples.
  double get bytesPerSecond {
    if (_samples.length < 2) {
      return 0;
    }

    final (firstTime, firstBytes) = _samples.first;
    final (lastTime, lastBytes) = _samples.last;
    final elapsed = lastTime.difference(firstTime).inMicroseconds;
    if (elapsed <= 0) {
      return 0;
    }

    return (lastBytes - firstBytes) * Duration.microsecondsPerSecond / elapsed;
  }
}
