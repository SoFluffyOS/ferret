import 'package:ferret_messages/ferret_messages.dart';
import 'package:fixnum/fixnum.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/sms_source.dart';
import 'package:protocol/messages.dart';

/// An [SmsSource] backed by Android's SMS and MMS providers.
class PlatformSmsSource implements SmsSource {
  PlatformSmsSource([FerretMessages? platform])
    : _platform = platform ?? FerretMessages();

  final FerretMessages _platform;

  @override
  Stream<void> get changes => _platform.changes;

  @override
  Future<SmsAccess> access() async => accessOf(await _platform.access());

  @override
  Future<SmsAccess> requestAccess() async =>
      accessOf(await _platform.requestAccess());

  @override
  Future<bool> openAppSettings() => _platform.openAppSettings();

  @override
  Future<ConversationPage> listConversations({
    int beforeDateMs = 0,
    required int limit,
  }) async {
    final page = await _platform.listConversations(
      beforeDateMs: beforeDateMs,
      limit: limit,
    );
    return ConversationPage(
      conversations: page.conversations.map(conversationOf),
      hasMore: page.hasMore,
    );
  }

  @override
  Future<List<Conversation>> conversationsById(List<int> threadIds) async {
    final conversations = await _platform.conversationsById(threadIds);
    return [
      for (final conversation in conversations) conversationOf(conversation),
    ];
  }

  @override
  Future<MessagePage> listMessages(
    int threadId, {
    int beforeDateMs = 0,
    List<String> skipIds = const [],
    required int limit,
  }) async {
    final page = await _platform.listMessages(
      threadId,
      beforeDateMs: beforeDateMs,
      skipIds: skipIds,
      limit: limit,
    );
    return MessagePage(
      threadId: Int64(threadId),
      messages: page.messages.map(messageOf),
      hasMore: page.hasMore,
    );
  }

  @override
  Future<List<Message>> recentMessages({
    required int sinceDateMs,
    required int limit,
  }) async {
    final messages = await _platform.recentMessages(
      sinceDateMs: sinceDateMs,
      limit: limit,
    );
    return [for (final message in messages) messageOf(message)];
  }

  @override
  Future<AttachmentData?> fetchAttachment(
    String messageId,
    String partId,
  ) async {
    final data = await _platform.fetchAttachment(messageId, partId);
    if (data == null) {
      return null;
    }

    return AttachmentData(mime: data.mime, data: data.data);
  }

  @override
  Future<SendResult> send(SendText request) async {
    final result = await _platform.send(
      threadId: request.threadId.toInt(),
      addresses: request.addresses,
      text: request.text,
    );
    return SendResult(
      ok: result.failure == .none,
      failure: failureOf(result.failure),
      threadId: Int64(result.threadId),
    );
  }

  @override
  Future<bool> markRead(int threadId) => _platform.markRead(threadId);

  @override
  Future<void> startWatching() => _platform.startWatching();

  @override
  Future<void> stopWatching() => _platform.stopWatching();

  static SmsAccess accessOf(PlatformAccess access) => SmsAccess(
    hasTelephony: access.hasTelephony,
    canRead: access.canRead,
    canSend: access.canSend,
    canReadContacts: access.canReadContacts,
    blocked: access.blocked,
  );

  static Conversation conversationOf(PlatformConversation conversation) =>
      Conversation(
        threadId: Int64(conversation.threadId),
        participants: [
          for (final participant in conversation.participants)
            Participant(
              address: participant.address,
              name: participant.name,
              avatarJpeg: participant.avatarJpeg,
            ),
        ],
        snippet: conversation.snippet,
        lastDateMs: Int64(conversation.lastDateMs),
        unreadCount: conversation.unreadCount,
        isGroup: conversation.isGroup,
      );

  static Message messageOf(PlatformMessage message) => Message(
    id: message.id,
    threadId: Int64(message.threadId),
    senderAddress: message.senderAddress,
    body: message.body,
    dateMs: Int64(message.dateMs),
    kind: kindOf(message.kind),
    attachments: [
      for (final attachment in message.attachments)
        Attachment(
          partId: attachment.partId,
          mime: attachment.mime,
          size: Int64(attachment.size),
          thumbnailJpeg: attachment.thumbnailJpeg,
          name: attachment.name,
        ),
    ],
    read: message.read,
  );

  static MessageKind kindOf(PlatformMessageKind kind) => switch (kind) {
    .inbox => .MESSAGE_KIND_INBOX,
    .sent => .MESSAGE_KIND_SENT,
    .outbox => .MESSAGE_KIND_OUTBOX,
    .failed => .MESSAGE_KIND_FAILED,
    .queued => .MESSAGE_KIND_QUEUED,
  };

  static SendFailure failureOf(PlatformSendFailure failure) =>
      switch (failure) {
        .none => .SEND_FAILURE_UNSPECIFIED,
        .noAccess => .SEND_FAILURE_NO_ACCESS,
        .noRecipient => .SEND_FAILURE_NO_RECIPIENT,
        .group => .SEND_FAILURE_GROUP,
        .noService => .SEND_FAILURE_NO_SERVICE,
        .timeout => .SEND_FAILURE_TIMEOUT,
        .other => .SEND_FAILURE_OTHER,
      };
}
