import 'package:core/core.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/services/handoff_settings.dart';
import 'package:protobuf/protobuf.dart';

/// The last activities that went between devices, newest first, kept in
/// settings so they survive a restart.
class HandoffTimeline {
  HandoffTimeline(this._settings, {this.capacity = 50});

  /// Larger app state isn't worth keeping in history.
  static const _maxStoredStateBytes = 2048;

  final SettingsStore _settings;
  final int capacity;
  final List<TimelineEntry> _entries = [];

  List<TimelineEntry> get entries => List.unmodifiable(_entries);

  void load() {
    final stored = _settings.get<List<Object?>>(HandoffSettings.timeline);
    if (stored == null) {
      return;
    }

    _entries
      ..clear()
      ..addAll([
        for (final json in stored) ?TimelineEntry.fromJson(json),
      ]);
    _trim();
  }

  /// Adds [entry] on top; the same activity in the same direction moves up
  /// instead of appearing twice.
  Future<void> add(TimelineEntry entry) async {
    final activity = entry.activity.deepCopy();
    if (activity.state.length > _maxStoredStateBytes) {
      activity
        ..clearState()
        ..clearStateType();
    }

    _entries
      ..removeWhere(
        (existing) =>
            existing.activity.id == activity.id &&
            existing.direction == entry.direction,
      )
      ..insert(
        0,
        TimelineEntry(
          activity: activity,
          peer: entry.peer,
          direction: entry.direction,
          at: entry.at,
        ),
      );
    _trim();
    await _save();
  }

  Future<void> clear() async {
    _entries.clear();
    await _save();
  }

  void _trim() {
    if (_entries.length > capacity) {
      _entries.removeRange(capacity, _entries.length);
    }
  }

  Future<void> _save() => _settings.set(HandoffSettings.timeline, [
    for (final entry in _entries) entry.toJson(),
  ]);
}
