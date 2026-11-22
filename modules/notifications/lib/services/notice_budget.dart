/// Keeps a busy app, or a busy phone, from filling the screen: at most
/// [limit] notices per key in any [window]. Past that, notifications wait
/// quietly in Ferret's list, the way Android 15 turns down an app that posts
/// in a burst.
class NoticeBudget {
  NoticeBudget({required this.limit, this.window = const Duration(minutes: 1)});

  final int limit;
  final Duration window;

  final Map<String, List<DateTime>> _shown = {};

  /// Whether [key] may show another notice at [at].
  bool allows(String key, DateTime at) {
    final times = _shown[key];
    if (times == null) {
      return true;
    }

    times.removeWhere((time) => at.difference(time) >= window);
    return times.length < limit;
  }

  /// Counts a notice [key] showed at [at].
  void spend(String key, DateTime at) =>
      _shown.putIfAbsent(key, () => []).add(at);

  /// Forgets the keys [test] picks, such as a removed phone's.
  void forget(bool Function(String key) test) =>
      _shown.removeWhere((key, _) => test(key));
}
