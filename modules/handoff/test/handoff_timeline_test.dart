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

DateTime _now() => DateTime(2026, 1, 20);

void main() {
  test('the timeline keeps the newest 50 entries', () async {
    final timeline = HandoffTimeline(MemorySettingsStore(), now: _now);

    for (var index = 0; index < 60; index++) {
      await timeline.add(_entry('a$index'));
    }

    expect(timeline.entries, hasLength(50));
    expect(timeline.entries.first.activity.id, 'a59');
    expect(timeline.entries.last.activity.id, 'a10');
  });

  test('the same activity moves up instead of repeating', () async {
    final timeline = HandoffTimeline(MemorySettingsStore(), now: _now);

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
    await HandoffTimeline(settings, now: _now).add(
      TimelineEntry(
        activity: big,
        peer: pixel,
        direction: .sent,
        at: DateTime(2026, 3, 4),
      ),
    );

    final reloaded = HandoffTimeline(settings, now: _now)..load();

    final entry = reloaded.entries.single;
    expect(entry.activity.uri, 'https://example.org/big');
    expect(entry.activity.state, isEmpty);
    expect(entry.peer.name, 'Pixel');
    expect(entry.direction, TimelineDirection.sent);
    expect(entry.at, DateTime(2026, 3, 4));
  });

  test(
    'whether it was sent on purpose and opened survives a restart',
    () async {
      final settings = MemorySettingsStore();
      await HandoffTimeline(settings, now: _now).add(
        TimelineEntry(
          activity: webActivity('a'),
          peer: pixel,
          direction: .received,
          at: DateTime(2026, 1, 2),
          isExplicit: true,
          openFailed: true,
        ),
      );

      final entry = (HandoffTimeline(
        settings,
        now: _now,
      )..load()).entries.single;

      expect(entry.isExplicit, isTrue);
      expect(entry.openFailed, isTrue);
    },
  );

  test('an entry kept before these flags counts sent ones as explicit', () {
    final stored = _entry('a', direction: .sent).toJson()
      ..remove('explicit')
      ..remove('open_failed');
    final received = _entry('b').toJson()..remove('explicit');

    expect(TimelineEntry.fromJson(stored)?.isExplicit, isTrue);
    expect(TimelineEntry.fromJson(stored)?.openFailed, isFalse);
    expect(TimelineEntry.fromJson(received)?.isExplicit, isFalse);
  });

  test('broken stored entries are skipped', () {
    final settings = MemorySettingsStore({
      HandoffSettings.timeline: [
        {'activity': 'not base64!'},
        42,
        _entry('ok').toJson(),
      ],
    });

    final timeline = HandoffTimeline(settings, now: _now)..load();

    expect(timeline.entries.single.activity.id, 'ok');
  });

  test('entries older than 30 days go, on load and on every add', () async {
    var today = DateTime(2026, 1, 20);
    final settings = MemorySettingsStore();
    final timeline = HandoffTimeline(settings, now: () => today);
    await timeline.add(_entry('old'));

    today = DateTime(2026, 2, 15);
    await timeline.add(
      TimelineEntry(
        activity: webActivity('new'),
        peer: pixel,
        direction: .received,
        at: today,
      ),
    );

    expect(timeline.entries.map((entry) => entry.activity.id), ['new']);
    expect(
      (HandoffTimeline(settings, now: () => today)..load()).entries,
      hasLength(1),
    );
  });
}
