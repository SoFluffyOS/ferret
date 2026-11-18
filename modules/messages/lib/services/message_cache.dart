import 'dart:convert';
import 'dart:math' as math;

import 'package:protocol/messages.dart';

/// One phone's conversations and texts as a computer keeps them: merged from
/// pages and pushes without duplicates, trimmed to a size that stays quick to
/// load, and saved as JSON so history survives a disconnect.
class MessageCache {
  MessageCache();

  static const formatVersion = 1;
  static const maxConversations = 300;
  static const maxMessagesPerThread = 300;

  final Map<int, Conversation> _conversations = {};
  final Map<int, _Thread> _threads = {};

  /// The last date of each conversation when it was read here. The phone
  /// can't mark texts read unless Ferret is its default app, so this keeps
  /// the unread count honest on the computer.
  final Map<int, int> _readUpTo = {};

  /// Older conversations may exist on the phone.
  bool hasMoreConversations = true;

  bool get isEmpty => _conversations.isEmpty;

  /// Newest first, with conversations read here shown as read.
  List<Conversation> get conversations {
    final sorted = _conversations.values.toList()..sort(_newestFirst);
    return [for (final conversation in sorted) _withReadState(conversation)];
  }

  Conversation? conversation(int threadId) =>
      switch (_conversations[threadId]) {
        final Conversation found => _withReadState(found),
        null => null,
      };

  /// Oldest first, as a thread is read.
  List<Message> messages(int threadId) {
    final thread = _threads[threadId];
    if (thread == null) {
      return const [];
    }

    return thread.messages.values.toList()..sort(_oldestFirst);
  }

  bool hasMessages(int threadId) =>
      _threads[threadId]?.messages.isNotEmpty ?? false;

  /// Older texts may exist on the phone for [threadId].
  bool hasOlderMessages(int threadId) => _threads[threadId]?.hasOlder ?? true;

  int get unreadTotal => conversations.fold(
    0,
    (total, conversation) => total + conversation.unreadCount,
  );

  /// Where the next page of older conversations starts.
  int get oldestConversationDateMs {
    if (_conversations.isEmpty) {
      return 0;
    }

    return _conversations.values
        .map((conversation) => conversation.lastDateMs.toInt())
        .reduce(math.min);
  }

  /// Where the next page of older texts in [threadId] starts: the oldest
  /// date held, and the ids held at exactly that date.
  ({int beforeDateMs, List<String> skipIds}) olderCursor(int threadId) {
    final held = messages(threadId);
    if (held.isEmpty) {
      return (beforeDateMs: 0, skipIds: const []);
    }

    final oldest = held.first.dateMs.toInt();
    return (
      beforeDateMs: oldest,
      skipIds: [
        for (final message in held)
          if (message.dateMs.toInt() == oldest) message.id,
      ],
    );
  }

  /// Merges a page of conversations. The newest page is the truth for the
  /// dates it covers, so conversations deleted on the phone go away here too.
  void mergeConversationPage(ConversationPage page, {required bool newest}) {
    final received = {
      for (final conversation in page.conversations)
        conversation.threadId.toInt(): conversation,
    };

    if (newest) {
      final covered = switch (page.hasMore) {
        true => _oldestDate(page.conversations),
        false => null,
      };
      final gone = [
        for (final MapEntry(key: threadId, value: conversation)
            in _conversations.entries)
          if (!received.containsKey(threadId) &&
              (covered == null || conversation.lastDateMs.toInt() >= covered))
            threadId,
      ];
      gone.forEach(_forgetConversation);
      final olderHeld = _conversations.keys.any(
        (threadId) => !received.containsKey(threadId),
      );
      hasMoreConversations =
          page.hasMore && (!olderHeld || hasMoreConversations);
    }

    if (!newest) {
      hasMoreConversations = page.hasMore;
    }

    _conversations.addAll(received);
    _trimConversations();
  }

  /// Merges a page of texts of [threadId]. The newest page is the truth for
  /// the dates it covers.
  void mergeMessagePage(
    int threadId,
    MessagePage page, {
    required bool newest,
  }) {
    final thread = _threads.putIfAbsent(threadId, _Thread.new);

    if (newest) {
      final covered = switch (page.hasMore) {
        true => _oldestMessageDate(page.messages),
        false => null,
      };
      final pageIds = {for (final message in page.messages) message.id};
      thread.messages.removeWhere(
        (id, message) =>
            !pageIds.contains(id) &&
            (covered == null || message.dateMs.toInt() >= covered),
      );
      final olderHeld = thread.messages.keys.any(
        (id) => !pageIds.contains(id),
      );
      thread.hasOlder = page.hasMore && (!olderHeld || thread.hasOlder);
    }

    if (!newest) {
      thread.hasOlder = page.hasMore;
    }

    for (final message in page.messages) {
      thread.messages[message.id] = message;
    }

    _trimThread(thread);
  }

  /// Applies a push from the phone. Returns the texts that were not held
  /// before.
  List<Message> applyChanges(MessagesChanged changes) {
    for (final conversation in changes.conversations) {
      _conversations[conversation.threadId.toInt()] = conversation;
    }

    final added = <Message>[];
    for (final message in changes.messages) {
      final thread = _threads.putIfAbsent(
        message.threadId.toInt(),
        _Thread.new,
      );
      if (!thread.messages.containsKey(message.id)) {
        added.add(message);
      }

      thread.messages[message.id] = message;
      _trimThread(thread);
    }

    _trimConversations();
    return added;
  }

  /// Marks [threadId] read up to its last text.
  bool markRead(int threadId) {
    final conversation = _conversations[threadId];
    if (conversation == null) {
      return false;
    }

    _readUpTo[threadId] = conversation.lastDateMs.toInt();
    return true;
  }

  Map<String, Object?> toJson() => {
    'version': formatVersion,
    'hasMoreConversations': hasMoreConversations,
    'conversations': [
      for (final conversation in _conversations.values)
        base64Encode(conversation.writeToBuffer()),
    ],
    'threads': {
      for (final MapEntry(key: threadId, value: thread) in _threads.entries)
        '$threadId': {
          'hasOlder': thread.hasOlder,
          'messages': [
            for (final message in thread.messages.values)
              base64Encode(message.writeToBuffer()),
          ],
        },
    },
    'readUpTo': {
      for (final MapEntry(key: threadId, value: dateMs) in _readUpTo.entries)
        '$threadId': dateMs,
    },
  };

  String encode() => jsonEncode(toJson());

  /// Reads a cache saved with [encode]. A file from another version or a
  /// damaged one gives an empty cache rather than an error.
  static MessageCache decode(String source) {
    final cache = MessageCache();
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return cache;
    }

    if (json is! Map<String, Object?> || json['version'] != formatVersion) {
      return cache;
    }

    try {
      cache._read(json);
    } on Object {
      return MessageCache();
    }

    return cache;
  }

  void _read(Map<String, Object?> json) {
    hasMoreConversations = json['hasMoreConversations'] != false;

    if (json['conversations'] case final List<Object?> encoded) {
      for (final item in encoded.whereType<String>()) {
        final conversation = Conversation.fromBuffer(base64Decode(item));
        _conversations[conversation.threadId.toInt()] = conversation;
      }
    }

    if (json['threads'] case final Map<String, Object?> threads) {
      for (final MapEntry(key: key, value: value) in threads.entries) {
        final threadId = int.tryParse(key);
        if (threadId == null || value is! Map<String, Object?>) {
          continue;
        }

        final thread = _threads.putIfAbsent(threadId, _Thread.new)
          ..hasOlder = value['hasOlder'] != false;
        if (value['messages'] case final List<Object?> encoded) {
          for (final item in encoded.whereType<String>()) {
            final message = Message.fromBuffer(base64Decode(item));
            thread.messages[message.id] = message;
          }
        }
      }
    }

    if (json['readUpTo'] case final Map<String, Object?> readUpTo) {
      for (final MapEntry(key: key, value: value) in readUpTo.entries) {
        if ((int.tryParse(key), value) case (
          final int threadId,
          final int dateMs,
        )) {
          _readUpTo[threadId] = dateMs;
        }
      }
    }
  }

  Conversation _withReadState(Conversation conversation) {
    final readUpTo = _readUpTo[conversation.threadId.toInt()];
    if (readUpTo == null ||
        conversation.unreadCount == 0 ||
        conversation.lastDateMs.toInt() > readUpTo) {
      return conversation;
    }

    return conversation.deepCopy()..unreadCount = 0;
  }

  void _forgetConversation(int threadId) {
    _conversations.remove(threadId);
    _threads.remove(threadId);
    _readUpTo.remove(threadId);
  }

  void _trimConversations() {
    if (_conversations.length <= maxConversations) {
      return;
    }

    final sorted = _conversations.values.toList()..sort(_newestFirst);
    for (final conversation in sorted.skip(maxConversations)) {
      _forgetConversation(conversation.threadId.toInt());
    }

    hasMoreConversations = true;
  }

  void _trimThread(_Thread thread) {
    if (thread.messages.length <= maxMessagesPerThread) {
      return;
    }

    final sorted = thread.messages.values.toList()..sort(_oldestFirst);
    final excess = sorted.length - maxMessagesPerThread;
    for (final message in sorted.take(excess)) {
      thread.messages.remove(message.id);
    }

    thread.hasOlder = true;
  }

  static int? _oldestDate(List<Conversation> conversations) {
    if (conversations.isEmpty) {
      return null;
    }

    return conversations
        .map((conversation) => conversation.lastDateMs.toInt())
        .reduce(math.min);
  }

  static int? _oldestMessageDate(List<Message> messages) {
    if (messages.isEmpty) {
      return null;
    }

    return messages.map((message) => message.dateMs.toInt()).reduce(math.min);
  }

  static int _newestFirst(Conversation a, Conversation b) {
    final byDate = b.lastDateMs.compareTo(a.lastDateMs);
    if (byDate != 0) {
      return byDate;
    }

    return b.threadId.compareTo(a.threadId);
  }

  static int _oldestFirst(Message a, Message b) {
    final byDate = a.dateMs.compareTo(b.dateMs);
    if (byDate != 0) {
      return byDate;
    }

    return a.id.compareTo(b.id);
  }
}

class _Thread {
  final Map<String, Message> messages = {};
  bool hasOlder = true;
}
