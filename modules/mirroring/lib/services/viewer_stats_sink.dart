/// A feed that wants this computer's numbers once a second, such as to
/// measure the round trip or to steer the other side's bitrate.
abstract interface class ViewerStatsSink {
  /// [fps] pictures were shown and [droppedFrames] skipped since the last
  /// report, made at [sentAt].
  void reportStats({
    required DateTime sentAt,
    required int fps,
    required int droppedFrames,
  });
}
