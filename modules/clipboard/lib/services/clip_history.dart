import 'package:clipboard/models/models.dart';

/// The last few clips, newest first, kept in memory only.
class ClipHistory {
  ClipHistory({this.limit = 20});

  final int limit;
  final List<ClipEntry> _entries = [];

  List<ClipEntry> get entries => List.unmodifiable(_entries);

  ClipEntry? get latest => _entries.firstOrNull;

  void add(ClipEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > limit) {
      _entries.removeRange(limit, _entries.length);
    }
  }

  /// Replaces the entry with [id]; false when it is gone.
  bool update(String id, ClipEntry Function(ClipEntry entry) change) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) {
      return false;
    }

    _entries[index] = change(_entries[index]);
    return true;
  }

  /// Drops the entries [test] matches; true when any went.
  bool removeWhere(bool Function(ClipEntry entry) test) {
    final before = _entries.length;
    _entries.removeWhere(test);
    return _entries.length != before;
  }

  void clear() => _entries.clear();
}
