/// How the picture is doing, in one word.
enum ViewQuality {
  good,
  slow,
  poor;

  static const _slowLatencyMs = 80;
  static const _poorLatencyMs = 200;

  /// From one second of numbers. Frames shown aren't counted against a
  /// target: a phone showing a photo sends few, and that isn't slow.
  static ViewQuality of({
    required int shownFrames,
    required int droppedFrames,
    int? latencyMs,
  }) {
    final latency = latencyMs ?? 0;
    final total = shownFrames + droppedFrames;
    final droppedHalf = total > 0 && droppedFrames * 2 >= total;
    if (latency > _poorLatencyMs || droppedHalf) {
      return .poor;
    }

    if (latency > _slowLatencyMs || droppedFrames > 0) {
      return .slow;
    }

    return .good;
  }

  /// How many of the mark's three bars are filled.
  int get bars => switch (this) {
    .good => 3,
    .slow => 2,
    .poor => 1,
  };
}
