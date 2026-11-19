/// Lets at most [perMinute] notices from one device through each minute,
/// so a script stuck in a loop can't flood the screen.
class NoticeLimit {
  NoticeLimit({this.perMinute = 6, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final int perMinute;
  final DateTime Function() _clock;
  final Map<String, List<DateTime>> _shown = {};

  /// Whether one more notice from [deviceId] may show now; counts it if so.
  bool allow(String deviceId) {
    final now = _clock();
    final cutoff = now.subtract(const Duration(minutes: 1));
    final recent = [
      for (final at in _shown[deviceId] ?? const <DateTime>[])
        if (at.isAfter(cutoff)) at,
    ];
    if (recent.length >= perMinute) {
      _shown[deviceId] = recent;
      return false;
    }

    _shown[deviceId] = [...recent, now];
    return true;
  }
}
