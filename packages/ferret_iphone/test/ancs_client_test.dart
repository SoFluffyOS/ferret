import 'package:fake_async/fake_async.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:ferret_iphone/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAppleTransport transport;
  late FakeIphone iphone;
  late AncsClient client;
  late List<AncsEvent> events;

  Future<void> start({Duration timeout = const Duration(seconds: 5)}) async {
    transport = FakeAppleTransport();
    iphone = FakeIphone(transport);
    await transport.connect('iphone');
    client = AncsClient(transport, requestTimeout: timeout);
    events = [];
    client.events.listen(events.add);
    await client.start();
  }

  test('subscribes to Data Source before Notification Source', () async {
    await start();

    expect(transport.notifying.toList(), [
      AppleCharacteristic.dataSource,
      AppleCharacteristic.notificationSource,
    ]);
  });

  test('reports events and fetches the text of one', () async {
    await start();

    iphone.notify(
      7,
      appId: 'com.apple.MobileSMS',
      title: 'Zoé',
      message: 'On my way',
      date: '20261118T093005',
    );
    final notification = await client.fetch(events.single);

    expect(events.single.uid, 7);
    expect(events.single.hasNegativeAction, isTrue);
    expect(notification.appId, 'com.apple.MobileSMS');
    expect(notification.title, 'Zoé');
    expect(notification.message, 'On my way');
    expect(notification.date, DateTime(2026, 11, 18, 9, 30, 5));
    expect(notification.negativeActionLabel, 'Clear');
  });

  test('puts an answer split over small packets back together', () async {
    await start();
    iphone.packetSize = 20;

    iphone.notify(1, title: 'Long', message: 'word ' * 40);
    final notification = await client.fetch(events.single);

    expect(notification.message, 'word ' * 40);
  });

  test('asks for text up to the max length', () async {
    await start();
    client = AncsClient(transport, maxTextLength: 10);
    await client.start();

    iphone.notify(1, message: 'a' * 50);
    final notification = await client.fetch(events.single);

    expect(notification.message, 'a' * 10);
  });

  test('answers one command at a time, in order', () async {
    await start();
    iphone
      ..notify(1, title: 'one')
      ..notify(2, title: 'two')
      ..notify(3, title: 'three');

    final fetched = await Future.wait(events.map(client.fetch));

    expect(fetched.map((notification) => notification.title), [
      'one',
      'two',
      'three',
    ]);
  });

  test('asks for an app name once, and falls back to the bundle id', () async {
    await start();
    iphone.apps['com.apple.MobileSMS'] = 'Messages';

    final first = await client.appName('com.apple.MobileSMS');
    final second = await client.appName('com.apple.MobileSMS');
    final unknown = await client.appName('com.example.gone');

    expect(first, 'Messages');
    expect(second, 'Messages');
    expect(unknown, 'com.example.gone');
    expect(transport.writesTo(.controlPoint), hasLength(2));
  });

  test('performs the positive and negative actions', () async {
    await start();

    await client.perform(4, .negative);
    await client.perform(5, .positive);

    expect(iphone.performed, [
      (4, AncsAction.negative),
      (5, AncsAction.positive),
    ]);
  });

  test(
    'a notification that is already gone fails with the ATT error',
    () async {
      await start();
      iphone.notify(1);
      iphone.notifications.clear();

      await expectLater(
        client.fetch(events.single),
        throwsA(
          isA<GattException>()
              .having((error) => error.failure, 'failure', GattFailure.att)
              .having((error) => error.attError, 'code', 0xA2),
        ),
      );

      iphone.notify(2, title: 'next');
      expect((await client.fetch(events.last)).title, 'next');
    },
  );

  test('gives up when the iPhone never answers, then works again', () {
    fakeAsync((async) {
      start(timeout: const Duration(seconds: 2));
      async.flushMicrotasks();
      iphone
        ..notify(1, title: 'lost')
        ..silent = true;

      Object? failure;
      client
          .fetch(events.single)
          .then<void>(
            (_) {},
            onError: (Object error) {
              failure = error;
            },
          );
      async.elapse(const Duration(seconds: 3));

      expect(
        failure,
        isA<GattException>().having(
          (error) => error.failure,
          'failure',
          GattFailure.timeout,
        ),
      );

      iphone.silent = false;
      String? title;
      client.fetch(events.single).then((notification) {
        title = notification.title;
      });
      async.flushMicrotasks();

      expect(title, 'lost');
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('a refused subscription surfaces as not bonded', () async {
    transport = FakeAppleTransport()
      ..notifyError = const GattException(.notBonded);
    await transport.connect('iphone');
    client = AncsClient(transport);

    await expectLater(
      client.start,
      throwsA(
        isA<GattException>().having(
          (error) => error.failure,
          'failure',
          GattFailure.notBonded,
        ),
      ),
    );
  });

  test('stopping fails the command in flight', () async {
    await start();
    iphone
      ..notify(1)
      ..silent = true;

    final fetch = client.fetch(events.single);
    await Future<void>.delayed(Duration.zero);
    client.stop();

    await expectLater(fetch, throwsA(isA<GattException>()));
  });
}
