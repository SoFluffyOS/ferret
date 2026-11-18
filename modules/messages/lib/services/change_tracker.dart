import 'package:protocol/messages.dart';

/// What the phone last told computers about its recent texts and top
/// conversations, so it pushes only what changed and never replays history.
class ChangeTracker {
  /// How far back a check looks for texts whose status changed, such as a
  /// reply going from outbox to sent.
  static const lookback = Duration(minutes: 5);

  /// How many of the newest conversations are compared on each check.
  static const watchedConversations = 10;

  final Map<String, ({int dateMs, int signature})> _messages = {};
  final Map<int, ({int lastDateMs, int signature})> _conversations = {};
  int _watermarkMs = 0;

  /// The date to ask for recent texts from.
  int get sinceMs => _watermarkMs - lookback.inMilliseconds;

  /// Remembers the current state without reporting it, such as when
  /// watching starts.
  void baseline(
    List<Message> messages,
    List<Conversation> conversations,
    int nowMs,
  ) {
    _messages.clear();
    _conversations.clear();
    _watermarkMs = nowMs;
    changedMessages(messages);
    changedConversations(conversations);
  }

  /// The texts that are new or changed since they were last seen.
  List<Message> changedMessages(Iterable<Message> messages) {
    final changed = <Message>[];
    final seen = <String>{};
    for (final message in messages) {
      if (!seen.add(message.id)) {
        continue;
      }

      final dateMs = message.dateMs.toInt();
      final signature = signatureOf(message);
      if (_messages[message.id]?.signature == signature) {
        continue;
      }

      _messages[message.id] = (dateMs: dateMs, signature: signature);
      changed.add(message);
      if (dateMs > _watermarkMs) {
        _watermarkMs = dateMs;
      }
    }

    _trim();
    return changed;
  }

  /// The conversations whose last text, snippet or unread count changed.
  List<Conversation> changedConversations(
    Iterable<Conversation> conversations,
  ) {
    final changed = <Conversation>[];
    for (final conversation in conversations) {
      final threadId = conversation.threadId.toInt();
      final signature = conversationSignatureOf(conversation);
      if (_conversations[threadId]?.signature == signature) {
        continue;
      }

      _conversations[threadId] = (
        lastDateMs: conversation.lastDateMs.toInt(),
        signature: signature,
      );
      changed.add(conversation);
    }

    return changed;
  }

  /// The last date a conversation had when it was last seen, or null when it
  /// is new to the tracker.
  int? lastDateOf(int threadId) => _conversations[threadId]?.lastDateMs;

  /// Whether [messageId] was reported already.
  bool knows(String messageId) => _messages.containsKey(messageId);

  static int signatureOf(Message message) => Object.hash(
    message.kind,
    message.read,
    message.body,
    message.attachments.length,
    message.threadId,
  );

  static int conversationSignatureOf(Conversation conversation) => Object.hash(
    conversation.lastDateMs,
    conversation.snippet,
    conversation.unreadCount,
    conversation.participants.length,
  );

  void _trim() {
    final cutoff = sinceMs - lookback.inMilliseconds;
    _messages.removeWhere((_, entry) => entry.dateMs < cutoff);
  }
}
