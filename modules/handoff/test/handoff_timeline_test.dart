import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';

import 'support/fakes.dart';

TimelineEntry _entry(String id, {TimelineDirection direction = .received}) =>
    TimelineEntry(
      activity: webActivity(id),
      peer: pixel,
      direction: direction,
      at: DateTime(2026),
    );

void main() {
  test('the timeline keeps the newest 50 entries', () async {
    final timeline = HandoffTimeline(MemorySettingsStore());

    for (var index = 0; index < 60; index++) {
      await timeline.add(_entry('a$index'));
    }

    expect(timeline.entries, hasLength(50));
    expect(timeline.entries.first.activity.id, 'a59');
    expect(timeline.entries.last.activity.id, 'a10');
  });

  test('the same activity moves up instead of repeating', () async {
    final timeline = HandoffTimeline(MemorySettingsStore());

    await timeline.add(_entry('a'));
    await timeline.add(_entry('b'));
    await timeline.add(_entry('a'));
    await timeline.add(_entry('a', direction: .sent));

    expect(
      timeline.entries.map((entry) => (entry.activity.id, entry.direction)),
      [
        ('a', TimelineDirection.sent),
        ('a', TimelineDirection.received),
        ('b', TimelineDirection.received),
      ],
    );
  });

  test('the timeline survives a restart, without large app state', () async {
    final settings = MemorySettingsStore();
    final big = webActivity('big')..state = List.filled(4096, 1);
    await HandoffTimeline(settings).add(
      TimelineEntry(
        activity: big,
        peer: pixel,
        direction: .sent,
        at: DateTime(2026, 3, 4),
      ),
    );

    final reloaded = HandoffTimeline(settings)..load();

    final entry = reloaded.entries.single;
    expect(entry.activity.uri, 'https://example.org/big');
    expect(entry.activity.state, isEmpty);
    expect(entry.peer.name, 'Pixel');
    expect(entry.direction, TimelineDirection.sent);
    expect(entry.at, DateTime(2026, 3, 4));
  });

  test('broken stored entries are skipped', () {
    final settings = MemorySettingsStore({
      HandoffSettings.timeline: [
        {'activity': 'not base64!'},
        42,
        _entry('ok').toJson(),
      ],
    });

    final timeline = HandoffTimeline(settings)..load();

    expect(timeline.entries.single.activity.id, 'ok');
  });
}
