import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';
import 'package:protocol/messages.dart';

import 'support/fakes.dart';

void main() {
  const phoneId = PhoneAndComputer.phoneId;
  const now = 1_800_000_000_000;
  late FakeSmsSource source;
  late PhoneAndComputer devices;
  late FakeNotifier notifier;
  late IncomingNotices notices;
  late Set<int> showing;
  late bool enabled;
  late List<(String, int)> opened;

  final strings = lookupMessagesLocalizations(const Locale('en'));

  setUp(() async {
    source = FakeSmsSource()
      ..addConversation(conversationOf(1, lastDateMs: now - 1000))
      ..addConversation(
        conversationOf(
          2,
          lastDateMs: now - 2000,
          participants: [
            Participant(address: '+15550002', name: 'Bo'),
            Participant(address: '+15550003', name: 'Cy'),
          ],
        ),
      );
    devices = await PhoneAndComputer.start(
      source: source,
      clock: () => DateTime.fromMillisecondsSinceEpoch(now),
    );
    notifier = FakeNotifier();
    showing = {};
    enabled = true;
    opened = [];
    notices = IncomingNotices(
      library: devices.library,
      notifier: notifier,
      enabled: () => enabled,
      isShowing: (_, threadId) => showing.contains(threadId),
      strings: () => strings,
      deviceName: (_) => 'Pixel',
      onOpen: (deviceId, threadId) => opened.add((deviceId, threadId)),
    )..start();
    await devices.connect();
  });

  tearDown(() async {
    await notices.stop();
    await devices.stop();
  });

  Future<void> receive(
    String id, {
    int threadId = 1,
    String body = 'Are you coming?',
    String sender = '+15550001',
    List<Attachment> attachments = const [],
    int offset = 0,
  }) async {
    source.addMessage(
      messageOf(
        id,
        threadId: threadId,
        dateMs: now + offset,
        body: body,
        sender: sender,
        read: false,
        attachments: attachments,
      ),
    );
    final conversation = source.conversations[threadId];
    if (conversation != null) {
      source.addConversation(
        conversation.deepCopy()
          ..lastDateMs = conversation.lastDateMs + 100000 + offset
          ..unreadCount += 1,
      );
    }

    source.notifyChanged();
    await settle();
  }

  String noticeId(int threadId) =>
      IncomingNotices.noticeIdFor(phoneId, threadId);

  test('a new text shows a notice with Reply', () async {
    await receive('sms:1');

    final notice = notifier.shown[noticeId(1)];
    expect(notice?.title, 'Alex');
    expect(notice?.body, 'Are you coming?');
    expect(notice?.channel, NoticeChannel.incoming);
    expect(notice?.category, IncomingNotices.messageCategory);
  });

  test('no notice for the conversation on screen', () async {
    showing.add(1);

    await receive('sms:1');

    expect(notifier.history, isEmpty);
  });

  test('no notice when turned off in Settings', () async {
    enabled = false;

    await receive('sms:1');

    expect(notifier.history, isEmpty);
  });

  test('more texts update one notice with a count', () async {
    await receive('sms:1');
    await receive('sms:2', body: 'Hello?', offset: 1);

    expect(notifier.shown, hasLength(1));
    expect(notifier.shown[noticeId(1)]?.title, 'Alex · 2 new');
    expect(notifier.shown[noticeId(1)]?.body, 'Hello?');
  });

  test('a picture without text says Photo', () async {
    await receive(
      'mms:1',
      body: '',
      attachments: [Attachment(partId: '5', mime: 'image/jpeg')],
    );

    expect(notifier.shown[noticeId(1)]?.body, 'Photo');
  });

  test('group texts name the sender and offer no Reply', () async {
    await receive('sms:9', threadId: 2, sender: '+15550003', body: 'Lunch?');

    final notice = notifier.shown[noticeId(2)];
    expect(notice?.title, 'Bo, Cy');
    expect(notice?.body, 'Cy: Lunch?');
    expect(notice?.category, IncomingNotices.groupCategory);
  });

  test(
    'Reply sends the text to the conversation and clears the notice',
    () async {
      await receive('sms:1');

      notifier.respond(
        NoticeResponse(
          noticeId: noticeId(1),
          actionId: IncomingNotices.replyActionId,
          replyText: 'Yes!',
        ),
      );
      await settle();

      expect(source.sent.single.text, 'Yes!');
      expect(source.sent.single.threadId.toInt(), 1);
      expect(notifier.cancelled, contains(noticeId(1)));
      expect(devices.library.unreadTotal(phoneId), 0);
    },
  );

  test('Reply from a notice with no text field (Linux) opens the '
      'conversation', () async {
    await receive('sms:1');

    notifier.respond(
      NoticeResponse(
        noticeId: noticeId(1),
        actionId: IncomingNotices.replyActionId,
      ),
    );
    await settle();

    expect(opened, [(phoneId, 1)]);
    expect(source.sent, isEmpty);
    expect(notifier.cancelled, contains(noticeId(1)));
  });

  test('a failed reply shows why on the problems channel', () async {
    await receive('sms:1');
    source.sendResult = SendResult(failure: .SEND_FAILURE_NO_SERVICE);

    notifier.respond(
      NoticeResponse(
        noticeId: noticeId(1),
        actionId: IncomingNotices.replyActionId,
        replyText: 'Yes!',
      ),
    );
    await settle();

    final problem = notifier.history.last;
    expect(problem.channel, NoticeChannel.problems);
    expect(problem.title, 'Reply not sent');
    expect(problem.body, 'Pixel has no signal.');
  });

  test('tapping the notice opens the conversation', () async {
    await receive('sms:1');

    notifier.respond(NoticeResponse(noticeId: noticeId(1)));
    await settle();

    expect(opened, [(phoneId, 1)]);
    expect(notifier.shown, isEmpty);
  });

  test('opening the conversation here clears its notice and count', () async {
    await receive('sms:1');
    await notices.clear(phoneId, 1);
    await receive('sms:2', offset: 1);

    expect(notifier.shown[noticeId(1)]?.title, 'Alex');
  });

  test('the categories carry Reply as a text action', () {
    final categories = IncomingNotices.categories(strings);

    final reply = categories.first.actions.first;
    expect(categories.map((category) => category.id), [
      'messages.message',
      'messages.group',
    ]);
    expect(reply.isReply, isTrue);
  });
}
