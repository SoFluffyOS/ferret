import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';
import 'package:protocol/messages.dart';

import 'support/fakes.dart';

void main() {
  const phoneId = PhoneAndComputer.phoneId;
  const now = 1_800_000_000_000;
  late FakeSmsSource source;
  late PhoneAndComputer devices;
  late List<LibraryEvent> events;

  Future<void> start({MemoryCacheStore? store, bool connect = true}) async {
    devices = await PhoneAndComputer.start(
      source: source,
      store: store,
      clock: () => DateTime.fromMillisecondsSinceEpoch(now),
    );
    events = [];
    devices.library.events.listen(events.add);
    if (connect) {
      await devices.connect();
    }
  }

  setUp(() {
    source = FakeSmsSource();
    for (var threadId = 1; threadId <= 45; threadId++) {
      source
        ..addConversation(
          conversationOf(
            threadId,
            lastDateMs: now - threadId * 1000,
            name: 'Person $threadId',
            unread: switch (threadId) {
              1 => 2,
              _ => 0,
            },
          ),
        )
        ..addMessage(
          messageOf(
            'sms:$threadId',
            threadId: threadId,
            dateMs: now - threadId * 1000,
          ),
        );
    }
  });

  tearDown(() => devices.stop());

  test('connecting syncs the 30 newest conversations with names', () async {
    await start();

    final cache = devices.library.cache(phoneId);
    expect(devices.library.phone(phoneId).readiness, PhoneReadiness.ready);
    expect(cache.conversations, hasLength(MessageLibrary.firstPageSize));
    expect(cache.conversations.first.title, 'Person 1');
    expect(cache.hasMoreConversations, isTrue);
    expect(devices.library.unreadTotal(phoneId), 2);
  });

  test('older conversations load page by page until the end', () async {
    await start();

    expect(await devices.library.loadOlderConversations(phoneId), isTrue);

    final cache = devices.library.cache(phoneId);
    expect(cache.conversations, hasLength(45));
    expect(cache.conversations.last.title, 'Person 45');
    expect(cache.hasMoreConversations, isFalse);
  });

  test('a thread loads newest first, then older pages without gaps', () async {
    for (var index = 0; index < 120; index++) {
      source.addMessage(
        messageOf(
          'sms:t$index',
          threadId: 1,
          dateMs: now - 500000 + index * 10,
        ),
      );
    }

    await start();
    await devices.library.loadNewestMessages(phoneId, 1);
    final cache = devices.library.cache(phoneId);
    expect(cache.messages(1), hasLength(MessageLibrary.messagePageSize));

    while (cache.hasOlderMessages(1)) {
      await devices.library.loadOlderMessages(phoneId, 1);
    }

    expect(cache.messages(1), hasLength(121));
    expect(cache.messages(1).first.id, 'sms:t0');
  });

  test('a new unread text arrives as an incoming event, once', () async {
    await start();

    source
      ..addMessage(
        messageOf(
          'sms:new',
          threadId: 2,
          dateMs: now,
          read: false,
          body: 'Ping',
        ),
      )
      ..addConversation(
        conversationOf(
          2,
          lastDateMs: now,
          name: 'Person 2',
          snippet: 'Ping',
          unread: 1,
        ),
      );
    source.notifyChanged();
    await settle();

    final incoming = events.whereType<IncomingMessage>().toList();
    expect(incoming, hasLength(1));
    expect(incoming.single.message.body, 'Ping');
    expect(incoming.single.conversation?.title, 'Person 2');
  });

  test(
    'texts found by syncing after a reconnect never become events',
    () async {
      await start();
      await devices.disconnect();

      source.addMessage(
        messageOf('sms:away', threadId: 3, dateMs: now, read: false),
      );
      source.addConversation(conversationOf(3, lastDateMs: now, unread: 1));
      await devices.connect();

      expect(events.whereType<IncomingMessage>(), isEmpty);
      expect(devices.library.unreadTotal(phoneId), 3);
    },
  );

  test('a reply is sent, then the thread reloads with it', () async {
    await start();
    source.sendResult = SendResult(ok: true);
    source.addMessage(
      messageOf(
        'sms:reply',
        threadId: 1,
        dateMs: now + 1,
        kind: .MESSAGE_KIND_SENT,
        body: 'On my way',
      ),
    );

    final outcome = await devices.library.send(phoneId, 1, 'On my way');

    expect(outcome, SendOutcome.sent);
    expect(source.sent.single.text, 'On my way');
    expect(source.sent.single.threadId.toInt(), 1);
    expect(devices.library.cache(phoneId).messages(1).last.id, 'sms:reply');
  });

  test('a reply the radio refused says why', () async {
    await start();
    source.sendResult = SendResult(failure: .SEND_FAILURE_NO_SERVICE);

    expect(await devices.library.send(phoneId, 1, 'hi'), SendOutcome.noService);
  });

  test('a reply while the phone is away is not attempted', () async {
    await start();
    await devices.disconnect();

    expect(await devices.library.send(phoneId, 1, 'hi'), SendOutcome.offline);
    expect(source.sent, isEmpty);
  });

  test('a phone that stops answering is reported as failing', () async {
    await start();
    devices.toPhone?.unresponsive = true;

    expect(await devices.library.loadNewestMessages(phoneId, 1), isFalse);

    final phone = devices.library.phone(phoneId);
    expect(phone.lastRoundTrip?.ok, isFalse);
    expect(phone.readiness, PhoneReadiness.unreachable);
  });

  test('history survives a disconnect and a restart', () async {
    final store = MemoryCacheStore();
    await start(store: store);
    await devices.library.loadNewestMessages(phoneId, 1);
    await devices.disconnect();

    expect(devices.library.phone(phoneId).readiness, PhoneReadiness.offline);
    expect(devices.library.cache(phoneId).conversations, hasLength(30));
    await devices.stop();

    await start(store: store, connect: false);

    expect(devices.library.hasHistory(phoneId), isTrue);
    expect(devices.library.cache(phoneId).messages(1).single.id, 'sms:1');
  });

  test('reading a thread here clears its unread count', () async {
    await start();

    await devices.library.markRead(phoneId, 1);

    expect(devices.library.unreadTotal(phoneId), 0);
    expect(source.markedRead, [1]);
  });

  test('forgetting deletes the saved texts', () async {
    final store = MemoryCacheStore();
    await start(store: store);
    await devices.library.flush();
    expect(store.files, contains(phoneId));

    await devices.library.forget(phoneId);

    expect(store.files, isEmpty);
    expect(devices.library.hasHistory(phoneId), isFalse);
  });

  test('connecting syncs the first page once', () async {
    await start();

    final firstPages = source.conversationLimits.where(
      (limit) => limit == MessageLibrary.firstPageSize,
    );
    expect(firstPages, hasLength(1));
  });
}
