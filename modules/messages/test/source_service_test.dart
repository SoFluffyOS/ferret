import 'package:engine/engine.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';
import 'package:protocol/messages.dart';
import 'package:protocol/protocol.dart';

import 'support/fakes.dart';

void main() {
  const now = 1_800_000_000_000;
  late FakeSmsSource source;
  late PhoneAndComputer devices;

  Future<void> start({bool enabled = true}) async {
    devices = await PhoneAndComputer.start(
      source: source,
      enabled: enabled,
      clock: () => DateTime.fromMillisecondsSinceEpoch(now),
    );
    await devices.connect();
  }

  setUp(() {
    source = FakeSmsSource()
      ..addConversation(conversationOf(1, lastDateMs: now - 60000))
      ..addMessage(messageOf('sms:1', threadId: 1, dateMs: now - 60000));
  });

  tearDown(() => devices.stop());

  List<MessagesChanged> pushesToComputer() => [
    for (final push in devices.toComputer?.pushes ?? const [])
      if (push case final MessagesChanged changes) changes,
  ];

  test('the phone answers its status even when Messages is off', () async {
    await start(enabled: false);

    final status = await devices.toPhone?.call(
      MessagesFeature.featureId,
      StatusRequest(),
      MessagesStatus.new,
    );

    expect(status?.enabled, isFalse);
    expect(status?.smsAccess, isTrue);
  });

  test('requests are refused while Messages is off', () async {
    await start(enabled: false);

    await expectLater(
      devices.toPhone?.call(
        MessagesFeature.featureId,
        ListConversations(limit: 30),
        ConversationPage.new,
      ),
      throwsA(
        isA<RemoteErrorException>().having(
          (RemoteErrorException error) => error.code,
          'code',
          ErrorCode.ERROR_CODE_DENIED,
        ),
      ),
    );
  });

  test('watching runs only while a computer is connected', () async {
    await start();
    expect(source.watching, isTrue);

    await devices.disconnect();

    expect(source.watching, isFalse);
  });

  test('turning Messages off tells computers and stops watching', () async {
    await start();

    await devices.phone.settings.setEnabled(false);
    await settle();

    expect(source.watching, isFalse);
    expect(
      devices.library.phone(PhoneAndComputer.phoneId).readiness,
      PhoneReadiness.off,
    );
  });

  test('texts already on the phone are never pushed again', () async {
    await start();

    source.notifyChanged();
    await settle();

    expect(pushesToComputer(), isEmpty);
  });

  test('a new text is pushed once with its conversation', () async {
    await start();

    source
      ..addMessage(
        messageOf('sms:2', threadId: 1, dateMs: now, body: 'New', read: false),
      )
      ..addConversation(
        conversationOf(1, lastDateMs: now, snippet: 'New', unread: 1),
      );
    source.notifyChanged();
    await settle();
    source.notifyChanged();
    await settle();

    final pushes = pushesToComputer();
    expect(pushes, hasLength(1));
    expect(pushes.single.messages.single.id, 'sms:2');
    expect(pushes.single.conversations.single.unreadCount, 1);
  });

  test('a sent text going from outbox to sent is pushed again', () async {
    await start();
    final outgoing = messageOf(
      'sms:3',
      threadId: 1,
      dateMs: now,
      kind: .MESSAGE_KIND_OUTBOX,
    );
    source.addMessage(outgoing);
    source.notifyChanged();
    await settle();

    source.threads[1]?.remove(outgoing);
    source.addMessage(outgoing.deepCopy()..kind = .MESSAGE_KIND_SENT);
    source.notifyChanged();
    await settle();

    final kinds = [
      for (final push in pushesToComputer())
        for (final message in push.messages) message.kind,
    ];
    expect(kinds, [
      MessageKind.MESSAGE_KIND_OUTBOX,
      MessageKind.MESSAGE_KIND_SENT,
    ]);
  });

  test(
    'a late MMS with an old date is found through its conversation',
    () async {
      await start();

      source
        ..addMessage(
          messageOf('mms:7', threadId: 1, dateMs: now - 50000, read: false),
        )
        ..addConversation(
          conversationOf(1, lastDateMs: now - 50000, unread: 1),
        );
      source.notifyChanged();
      await settle();

      expect(pushesToComputer().single.messages.single.id, 'mms:7');
    },
  );

  test('pages pass the cursor through to the providers', () async {
    await start();
    for (var index = 0; index < 5; index++) {
      source.addMessage(
        messageOf('sms:x$index', threadId: 1, dateMs: now - 1000),
      );
    }

    final page = await devices.toPhone?.call(
      MessagesFeature.featureId,
      ListMessages(
        threadId: Int64(1),
        beforeDateMs: Int64(now - 1000),
        skipIds: ['sms:x4', 'sms:x3'],
        limit: 2,
      ),
      MessagePage.new,
    );

    expect(page?.messages.map((message) => message.id), ['sms:x2', 'sms:x1']);
    expect(page?.hasMore, isTrue);
    expect(page?.threadId.toInt(), 1);
  });

  test('a reply without SMS send access says so', () async {
    source.canSend = false;
    await start();

    final result = await devices.toPhone?.call(
      MessagesFeature.featureId,
      SendText(threadId: Int64(1), text: 'hi'),
      SendResult.new,
    );

    expect(result?.ok, isFalse);
    expect(result?.failure, SendFailure.SEND_FAILURE_NO_ACCESS);
    expect(source.sent, isEmpty);
  });

  test('marking read reports that Android ignored it', () async {
    await start();

    final result = await devices.toPhone?.call(
      MessagesFeature.featureId,
      MarkRead(threadId: Int64(1)),
      MarkReadResult.new,
    );

    expect(result?.applied, isFalse);
    expect(source.markedRead, [1]);
  });
}
