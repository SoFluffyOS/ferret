import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iphone/iphone.dart';

import 'helpers/fakes.dart';

void main() {
  late Rig rig;
  late List<FeedEvent> events;

  Future<void> start() async {
    rig = await Rig.start(settings: pairedSettings(), retryDelays: const []);
    await settle();
    rig.iphone.apps['com.apple.MobileSMS'] = 'Messages';
    events = [];
    rig.feature.notifications.listen(events.add);
    addTearDown(rig.feature.stop);
  }

  List<IphoneNotification> shown() => [
    for (final event in events)
      if (event case FeedShown(:final notification)) notification,
  ];

  test('shows a new notification with its text and the app name', () async {
    await start();

    rig.iphone.notify(
      7,
      appId: 'com.apple.MobileSMS',
      title: 'Zoé',
      subtitle: 'Family',
      message: 'On my way',
      date: '20261118T093005',
      category: .social,
    );
    await settle();

    final notification = shown().single;
    expect(notification.uid, 7);
    expect(notification.appName, 'Messages');
    expect(notification.title, 'Zoé');
    expect(notification.subtitle, 'Family');
    expect(notification.message, 'On my way');
    expect(notification.date, DateTime(2026, 11, 18, 9, 30, 5));
    expect(notification.category, AncsCategory.social);
    expect(notification.isUpdate, isFalse);
    expect(notification.hasNegativeAction, isTrue);
    expect(notification.hasPositiveAction, isFalse);
  });

  test('never replays what was already on the iPhone', () async {
    await start();

    for (var uid = 1; uid <= 20; uid++) {
      rig.iphone.notify(uid, title: 'Old $uid', preExisting: true);
    }
    await settle();

    expect(events, isEmpty);
    expect(rig.transport.writesTo(.controlPoint), isEmpty);

    rig.iphone.notify(21, title: 'New');
    await settle();

    expect(shown().single.title, 'New');
  });

  test(
    'falls back to the bundle id for an app the iPhone can not name',
    () async {
      await start();

      rig.iphone.notify(1, appId: 'com.example.unknown', title: 'Hi');
      await settle();

      expect(shown().single.appName, 'com.example.unknown');
    },
  );

  test('marks a change to a shown notification as an update', () async {
    await start();

    rig.iphone.notify(3, title: 'One message');
    await settle();
    rig.iphone.notify(3, title: 'Two messages', kind: .modified);
    await settle();

    expect(shown().map((notification) => notification.title), [
      'One message',
      'Two messages',
    ]);
    expect(shown().map((notification) => notification.isUpdate), [false, true]);
  });

  test('shows an old notification once it changes', () async {
    await start();

    rig.iphone.notify(3, title: 'Old', preExisting: true);
    rig.iphone.notify(3, title: 'Old, with news', kind: .modified);
    await settle();

    expect(shown().single.title, 'Old, with news');
    expect(shown().single.isUpdate, isFalse);
  });

  test('tells when a shown notification goes away, once', () async {
    await start();
    rig.iphone.notify(5, title: 'Hello');
    await settle();

    rig.iphone
      ..remove(5)
      ..remove(5)
      ..remove(99);
    await settle();

    expect(events.whereType<FeedRemoved>().map((event) => event.uid), [5]);
  });

  test('drops a notification that goes away while it is being read', () async {
    await start();

    rig.iphone.notify(5, title: 'Blink');
    rig.transport.emit(
      .notificationSource,
      [2, 0, 0, 0, 5, 0, 0, 0],
    );
    await settle();

    expect(events, isEmpty);
  });

  test('skips a notification the iPhone no longer knows', () async {
    await start();

    rig.iphone.notify(5, title: 'Gone');
    rig.iphone.notifications.clear();
    rig.iphone.notify(6, title: 'Here');
    await settle();

    expect(shown().single.title, 'Here');
  });

  test('after a reconnect, old handles mean nothing', () async {
    rig = await Rig.start(
      settings: pairedSettings(),
      retryDelays: const [Duration(milliseconds: 1)],
    );
    await settle();
    events = [];
    rig.feature.notifications.listen(events.add);
    addTearDown(rig.feature.stop);
    rig.iphone.notify(5, title: 'Before');
    await settle();

    rig.transport.drop();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await settle();
    rig.iphone
      ..notify(5, title: 'Before', preExisting: true)
      ..remove(5);
    await settle();

    expect(rig.feature.link.isConnected, isTrue);
    expect(shown().single.title, 'Before');
    expect(events.whereType<FeedRemoved>(), isEmpty);
  });
}
