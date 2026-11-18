import 'dart:collection';

/// Remembers the last [capacity] ids, to drop duplicates that arrive twice.
class RecentIds {
  RecentIds({this.capacity = 64});

  final int capacity;
  final LinkedHashSet<String> _ids = LinkedHashSet();

  /// Adds [id]; false when it was already there.
  bool add(String id) {
    if (_ids.contains(id)) {
      return false;
    }

    _ids.add(id);
    if (_ids.length > capacity) {
      _ids.remove(_ids.first);
    }

    return true;
  }
}
