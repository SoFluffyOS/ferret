import 'package:handoff/models/models.dart';

/// The suggestions this device shows, newest first. Each device has at most
/// one passive suggestion: a newer one replaces it.
class SuggestionBoard {
  SuggestionBoard({this.capacity = 20});

  final int capacity;
  final List<Suggestion> _items = [];

  /// Adds [suggestion] and returns the ones it replaced.
  List<Suggestion> add(Suggestion suggestion) {
    final replaced = [
      for (final existing in _items)
        if (_replaces(suggestion, existing)) existing,
    ];
    _items
      ..removeWhere(replaced.contains)
      ..insert(0, suggestion);

    while (_items.length > capacity) {
      replaced.add(_items.removeLast());
    }

    return replaced;
  }

  Suggestion? remove(String activityId) {
    final index = _items.indexWhere((item) => item.id == activityId);
    if (index < 0) {
      return null;
    }

    return _items.removeAt(index);
  }

  /// Removes what [deviceId] offered: one activity, or all with no id.
  List<Suggestion> clearFrom(String deviceId, {String activityId = ''}) {
    final removed = [
      for (final item in _items)
        if (item.from.id == deviceId &&
            (activityId.isEmpty || item.id == activityId))
          item,
    ];
    _items.removeWhere(removed.contains);
    return removed;
  }

  List<Suggestion> live(DateTime now) => [
    for (final item in _items)
      if (item.isLiveAt(now)) item,
  ];

  /// Drops expired suggestions and returns them.
  List<Suggestion> prune(DateTime now) {
    final expired = [
      for (final item in _items)
        if (!item.isLiveAt(now)) item,
    ];
    _items.removeWhere(expired.contains);
    return expired;
  }

  DateTime? get nextExpiry {
    DateTime? next;
    for (final item in _items) {
      if (next == null || item.expiresAt.isBefore(next)) {
        next = item.expiresAt;
      }
    }

    return next;
  }

  bool _replaces(Suggestion incoming, Suggestion existing) {
    if (existing.id == incoming.id) {
      return true;
    }

    return !incoming.isExplicit &&
        !existing.isExplicit &&
        existing.from.id == incoming.from.id;
  }
}
