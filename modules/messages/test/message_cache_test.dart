import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';
import 'package:protocol/messages.dart';

import 'support/fakes.dart';

void main() {
  late MessageCache cache;

  setUp(() => cache = MessageCache());

  ConversationPage conversationPage(List<int> threadIds, {bool more = false}) =>
      ConversationPage(
        conversations: [
          for (final threadId in threadIds)
            conversationOf(threadId, lastDateMs: threadId * 1000),
        ],
        hasMore: more,
      );

  MessagePage messagePage(List<Message> messages, {bool more = false}) =>
      MessagePage(threadId: Int64(1), messages: messages, hasMore: more);

  group('conversations', () {
    test('are newest first, with older pages appended', () {
      cache
        ..mergeConversationPage(
          conversationPage([9, 8], more: true),
          newest: true,
        )
        ..mergeConversationPage(conversationPage([7, 6]), newest: false);

      expect(
        cache.conversations.map(
          (conversation) => conversation.threadId.toInt(),
        ),
        [9, 8, 7, 6],
      );
      expect(cache.hasMoreConversations, isFalse);
      expect(cache.oldestConversationDateMs, 6000);
    });

    test('a page that repeats conversations keeps one of each', () {
      cache
        ..mergeConversationPage(
          conversationPage([9, 8], more: true),
          newest: true,
        )
        ..mergeConversationPage(conversationPage([8, 7]), newest: false);

      expect(cache.conversations, hasLength(3));
    });

    test('the newest page drops conversations deleted on the phone', () {
      cache.mergeConversationPage(conversationPage([9, 8, 7]), newest: true);

      cache.mergeConversationPage(conversationPage([9, 7]), newest: true);

      expect(
        cache.conversations.map(
          (conversation) => conversation.threadId.toInt(),
        ),
        [9, 7],
      );
    });

    test('the newest page keeps older pages it does not cover', () {
      cache
        ..mergeConversationPage(
          conversationPage([9, 8], more: true),
          newest: true,
        )
        ..mergeConversationPage(
          conversationPage([3, 2], more: true),
          newest: false,
        );

      cache.mergeConversationPage(
        conversationPage([10, 9], more: true),
        newest: true,
      );

      expect(
        cache.conversations.map(
          (conversation) => conversation.threadId.toInt(),
        ),
        [10, 9, 8, 3, 2],
      );
      expect(cache.hasMoreConversations, isTrue);
    });
  });

  group('messages', () {
    test('are oldest first and dedupe across pages', () {
      cache
        ..mergeMessagePage(
          1,
          messagePage([
            messageOf('sms:3', threadId: 1, dateMs: 3000),
            messageOf('sms:2', threadId: 1, dateMs: 2000),
          ], more: true),
          newest: true,
        )
        ..mergeMessagePage(
          1,
          messagePage([
            messageOf('sms:2', threadId: 1, dateMs: 2000),
            messageOf('sms:1', threadId: 1, dateMs: 1000),
          ]),
          newest: false,
        );

      expect(cache.messages(1).map((message) => message.id), [
        'sms:1',
        'sms:2',
        'sms:3',
      ]);
      expect(cache.hasOlderMessages(1), isFalse);
    });

    test('the older cursor skips texts held at the oldest date', () {
      cache.mergeMessagePage(
        1,
        messagePage([
          messageOf('mms:5', threadId: 1, dateMs: 2000),
          messageOf('sms:4', threadId: 1, dateMs: 2000),
          messageOf('sms:6', threadId: 1, dateMs: 3000),
        ], more: true),
        newest: true,
      );

      final cursor = cache.olderCursor(1);

      expect(cursor.beforeDateMs, 2000);
      expect(cursor.skipIds, unorderedEquals(['mms:5', 'sms:4']));
    });

    test('an unknown thread may have older texts and has no cursor', () {
      expect(cache.hasOlderMessages(42), isTrue);
      expect(cache.olderCursor(42).beforeDateMs, 0);
    });

    test('the newest page replaces changed texts and drops deleted ones', () {
      cache.mergeMessagePage(
        1,
        messagePage([
          messageOf(
            'sms:2',
            threadId: 1,
            dateMs: 2000,
            kind: .MESSAGE_KIND_OUTBOX,
          ),
          messageOf('sms:1', threadId: 1, dateMs: 1000),
        ]),
        newest: true,
      );

      cache.mergeMessagePage(
        1,
        messagePage([
          messageOf(
            'sms:2',
            threadId: 1,
            dateMs: 2000,
            kind: .MESSAGE_KIND_SENT,
          ),
        ]),
        newest: true,
      );

      expect(cache.messages(1).single.kind, MessageKind.MESSAGE_KIND_SENT);
    });
  });

  group('pushes', () {
    test('report only texts that were not held', () {
      cache.applyChanges(
        MessagesChanged(
          messages: [messageOf('sms:1', threadId: 1, dateMs: 1000)],
          conversations: [conversationOf(1, lastDateMs: 1000)],
        ),
      );

      final added = cache.applyChanges(
        MessagesChanged(
          messages: [
            messageOf('sms:1', threadId: 1, dateMs: 1000, read: false),
            messageOf('sms:2', threadId: 1, dateMs: 2000),
          ],
        ),
      );

      expect(added.map((message) => message.id), ['sms:2']);
      expect(cache.messages(1), hasLength(2));
      expect(cache.messages(1).first.read, isFalse);
    });
  });

  group('read here', () {
    test('clears the unread count until a newer text arrives', () {
      cache.applyChanges(
        MessagesChanged(
          conversations: [conversationOf(1, lastDateMs: 1000, unread: 2)],
        ),
      );

      cache.markRead(1);
      expect(cache.unreadTotal, 0);

      cache.applyChanges(
        MessagesChanged(
          conversations: [conversationOf(1, lastDateMs: 1000, unread: 2)],
        ),
      );
      expect(cache.unreadTotal, 0);

      cache.applyChanges(
        MessagesChanged(
          conversations: [conversationOf(1, lastDateMs: 2000, unread: 3)],
        ),
      );
      expect(cache.unreadTotal, 3);
    });
  });

  group('saving', () {
    test('survives a round trip through JSON', () {
      cache
        ..mergeConversationPage(conversationPage([2, 1]), newest: true)
        ..mergeMessagePage(
          2,
          MessagePage(
            threadId: Int64(2),
            messages: [
              messageOf('sms:9', threadId: 2, dateMs: 2000, body: 'Hey'),
            ],
          ),
          newest: true,
        )
        ..applyChanges(
          MessagesChanged(
            conversations: [conversationOf(1, lastDateMs: 1000, unread: 1)],
          ),
        )
        ..markRead(1);

      final restored = MessageCache.decode(cache.encode());

      expect(restored.conversations, hasLength(2));
      expect(restored.messages(2).single.body, 'Hey');
      expect(restored.hasOlderMessages(2), isFalse);
      expect(restored.hasMoreConversations, isFalse);
      expect(restored.unreadTotal, 0);
    });

    test('a damaged or foreign file gives an empty cache', () {
      expect(MessageCache.decode('not json').isEmpty, isTrue);
      expect(MessageCache.decode('{"version": 99}').isEmpty, isTrue);
      expect(
        MessageCache.decode('{"version": 1, "conversations": ["%%%"]}').isEmpty,
        isTrue,
      );
    });

    test('keeps at most the newest conversations', () {
      cache.mergeConversationPage(
        ConversationPage(
          conversations: [
            for (
              var threadId = 1;
              threadId <= MessageCache.maxConversations + 5;
              threadId++
            )
              conversationOf(threadId, lastDateMs: threadId),
          ],
        ),
        newest: true,
      );

      expect(cache.conversations, hasLength(MessageCache.maxConversations));
      expect(cache.conversations.last.threadId.toInt(), 6);
      expect(cache.hasMoreConversations, isTrue);
    });
  });
}
