import 'package:ferret_photos/ferret_photos.dart';

/// When a phone sends a new screenshot to a computer by itself.
abstract final class ScreenshotRule {
  /// How far before the computer asked a screenshot may be dated and still
  /// count as new, for a clock that lags a little.
  static const slack = Duration(seconds: 5);

  /// Only a screenshot, only to a computer that asked for them in this
  /// session and that the owner shares photos with, only one taken since
  /// it asked (nothing old is replayed after a reconnect), and only once.
  static bool shouldSend({
    required PhotoEntry entry,
    required bool isShared,
    required DateTime? subscribedAt,
    required Set<String> alreadySent,
  }) {
    if (entry.kind != .screenshot || !isShared) {
      return false;
    }

    if (subscribedAt == null || alreadySent.contains(entry.id)) {
      return false;
    }

    return !entry.takenAt.isBefore(subscribedAt.subtract(slack));
  }
}
