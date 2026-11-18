/// Remembers the last page published passively, so the same page isn't
/// offered again while the first offer still stands, whichever way it came
/// in (the macOS browser watch or the browser extension).
class RecentPublishes {
  RecentPublishes({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final DateTime Function() _now;
  ({String url, DateTime at})? _last;

  bool isRecent(String url, Duration within) {
    final last = _last;
    if (last == null || last.url != url) {
      return false;
    }

    return _now().difference(last.at) < within;
  }

  void mark(String url) => _last = (url: url, at: _now());
}
