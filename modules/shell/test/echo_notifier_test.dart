import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

class _Recording implements LocalNotifier {
  final Map<String, LocalNotice> showing = {};

  @override
  Future<void> show(LocalNotice notice) async => showing[notice.id] = notice;

  @override
  Future<void> cancel(String id) async => showing.remove(id);

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();
}

void main() {
  late _Recording system;
  late DateTime now;
  late EchoNotifier notifier;

  setUp(() {
    system = _Recording();
    now = DateTime(2026, 11, 23, 9);
    notifier = EchoNotifier(system, now: () => now);
  });

  LocalNotice text(String id, String body, {bool wins = false}) => LocalNotice(
    id: id,
    channel: .incoming,
    title: 'Mẹ',
    body: body,
    echo: NoticeEcho.text('pixel', body, wins: wins),
  );

  test('a text Messages showed does not pop up again from the mirrored '
      'Google Messages notification', () async {
    await notifier.show(text('messages/pixel/4', 'Về ăn cơm nhé', wins: true));
    await notifier.show(text('notifications/pixel/k1', 'Về ăn  cơm nhé '));

    expect(system.showing.keys, ['messages/pixel/4']);
  });

  test('the mirrored one arriving first gives way to Messages', () async {
    await notifier.show(text('notifications/pixel/k1', 'Running late'));
    await notifier.show(text('messages/pixel/4', 'Running late', wins: true));

    expect(system.showing.keys, ['messages/pixel/4']);
  });

  test('different texts, other phones and old news all show', () async {
    await notifier.show(text('messages/pixel/4', 'Running late', wins: true));
    await notifier.show(text('notifications/pixel/k1', 'On my way'));
    await notifier.show(
      LocalNotice(
        id: 'notifications/tab/k1',
        channel: .incoming,
        title: 'Mẹ',
        echo: NoticeEcho.text('tab', 'Running late'),
      ),
    );
    now = now.add(const Duration(minutes: 3));
    await notifier.show(text('notifications/pixel/k2', 'Running late'));

    expect(system.showing, hasLength(4));
  });

  test('a cancelled Messages notice no longer holds others back', () async {
    await notifier.show(text('messages/pixel/4', 'Running late', wins: true));
    await notifier.cancel('messages/pixel/4');
    await notifier.show(text('notifications/pixel/k1', 'Running late'));

    expect(system.showing.keys, ['notifications/pixel/k1']);
  });

  test('a missed call matches on the number\'s last digits', () async {
    await notifier.show(
      LocalNotice(
        id: 'calls/pixel/missed',
        channel: .incoming,
        title: 'Missed call',
        echo: NoticeEcho({
          NoticeEcho.callerKey('pixel', '+84 901 234 567'),
        }, wins: true),
      ),
    );
    await notifier.show(
      LocalNotice(
        id: 'notifications/pixel/dialer',
        channel: .incoming,
        title: 'Missed call',
        echo: NoticeEcho({
          NoticeEcho.callerKey('pixel', 'Missed call'),
          NoticeEcho.callerKey('pixel', '0901 234 567'),
        }),
      ),
    );

    expect(system.showing.keys, ['calls/pixel/missed']);
  });

  test('notices without an echo pass straight through', () async {
    await notifier.show(
      const LocalNotice(id: 'drop/1', channel: .transfers, title: 'Photo'),
    );
    unawaited(notifier.cancel('drop/1'));

    expect(system.showing, isEmpty);
  });
}
