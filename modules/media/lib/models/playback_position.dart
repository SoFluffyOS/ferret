/// Where a player is in its item, extrapolated from the last report so
/// devices never have to send the position on a timer.
abstract final class PlaybackPosition {
  /// The position at [nowMs], given that it was [positionMs] at
  /// [positionAtMs] (same clock as [nowMs]). Never goes past [durationMs]
  /// when that is known, nor below zero.
  static int at({
    required int nowMs,
    required int positionMs,
    required int positionAtMs,
    required bool playing,
    double rate = 1,
    int durationMs = 0,
  }) {
    if (!playing) {
      return _clamp(positionMs, durationMs);
    }

    final speed = switch (rate > 0) {
      true => rate,
      false => 1.0,
    };
    final elapsed = nowMs - positionAtMs;
    final moved = switch (elapsed > 0) {
      true => (elapsed * speed).round(),
      false => 0,
    };
    return _clamp(positionMs + moved, durationMs);
  }

  static int _clamp(int positionMs, int durationMs) {
    if (positionMs < 0) {
      return 0;
    }

    if (durationMs > 0 && positionMs > durationMs) {
      return durationMs;
    }

    return positionMs;
  }
}
