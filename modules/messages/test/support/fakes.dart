import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:fixnum/fixnum.dart';
import 'package:messages/messages.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/messages.dart';
import 'package:protocol/protocol.dart';

/// A phone's SMS providers in memory, paged the way the Android plugin pages.
class FakeSmsSource implements SmsSource {
  FakeSmsSource({
    this.hasTelephony = true,
    this.canRead = true,
    this.canSend = true,
    this.canReadContacts = true,
  });

  bool hasTelephony;
  bool canRead;
  bool canSend;
  bool canReadContacts;
  bool blocked = false;
  bool grantOnRequest = true;
  bool openSettingsWorks = true;
  bool watching = false;
  int requests = 0;
  int openedSettings = 0;
  SendResult sendResult = SendResult(ok: true);
  final List<SendText> sent = [];
  final List<int> markedRead = [];
  final List<int> conversationLimits = [];
  final Map<int, Conversation> conversations = {};
  final Map<int, List<Message>> threads = {};
  final StreamController<void> _changes = .broadcast(sync: true);

  void addConversation(Conversation conversation) =>
      conversations[conversation.threadId.toInt()] = conversation;

  void addMessage(Message message) {
    threads.putIfAbsent(message.threadId.toInt(), () => []).add(message);
  }

  /// Something changed in the providers.
  void notifyChanged() => _changes.add(null);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<SmsAccess> access() async => SmsAccess(
    hasTelephony: hasTelephony,
    canRead: canRead,
    canSend: canSend,
    canReadContacts: canReadContacts,
    blocked: blocked,
  );

  @override
  Future<SmsAccess> requestAccess() async {
    requests++;
    if (grantOnRequest) {
      canRead = true;
      canSend = true;
      canReadContacts = true;
    }

    return access();
  }

  @override
  Future<bool> openAppSettings() async {
    openedSettings++;
    return openSettingsWorks;
  }

  @override
  Future<ConversationPage> listConversations({
    int beforeDateMs = 0,
    required int limit,
  }) async {
    conversationLimits.add(limit);
    final matching =
        conversations.values
            .where(
              (conversation) =>
                  beforeDateMs == 0 ||
                  conversation.lastDateMs.toInt() < beforeDateMs,
            )
            .toList()
          ..sort((a, b) => b.lastDateMs.compareTo(a.lastDateMs));
    return ConversationPage(
      conversations: matching.take(limit),
      hasMore: matching.length > limit,
    );
  }

  @override
  Future<List<Conversation>> conversationsById(List<int> threadIds) async => [
    for (final threadId in threadIds) ?conversations[threadId],
  ];

  @override
  Future<MessagePage> listMessages(
    int threadId, {
    int beforeDateMs = 0,
    List<String> skipIds = const [],
    required int limit,
  }) async {
    final matching =
        (threads[threadId] ?? const <Message>[])
            .where(
              (message) =>
                  (beforeDateMs == 0 ||
                      message.dateMs.toInt() <= beforeDateMs) &&
                  !skipIds.contains(message.id),
            )
            .toList()
          ..sort(_newestFirst);
    return MessagePage(
      threadId: Int64(threadId),
      messages: matching.take(limit),
      hasMore: matching.length > limit,
    );
  }

  @override
  Future<List<Message>> recentMessages({
    required int sinceDateMs,
    required int limit,
  }) async {
    final matching = [
      for (final thread in threads.values)
        for (final message in thread)
          if (message.dateMs.toInt() > sinceDateMs) message,
    ]..sort(_newestFirst);
    return matching.take(limit).toList();
  }

  @override
  Future<AttachmentData?> fetchAttachment(
    String messageId,
    String partId,
  ) async {
    for (final thread in threads.values) {
      for (final message in thread) {
        if (message.id == messageId &&
            message.attachments.any((part) => part.partId == partId)) {
          return AttachmentData(mime: 'image/jpeg', data: [9, 9, 9]);
        }
      }
    }

    return null;
  }

  @override
  Future<SendResult> send(SendText request) async {
    sent.add(request);
    return sendResult;
  }

  @override
  Future<bool> markRead(int threadId) async {
    markedRead.add(threadId);
    return false;
  }

  @override
  Future<void> startWatching() async => watching = true;

  @override
  Future<void> stopWatching() async => watching = false;

  static int _newestFirst(Message a, Message b) {
    final byDate = b.dateMs.compareTo(a.dateMs);
    if (byDate != 0) {
      return byDate;
    }

    return b.id.compareTo(a.id);
  }
}

/// One side of a connection between two features in the same test: requests
/// run the other side's [Feature.onEnvelope] and come back as its reply.
class LinkedSession implements Session {
  LinkedSession(this.remoteDeviceId, {required this.name, required this.flags});

  @override
  final String remoteDeviceId;
  final String name;
  final List<String> flags;

  /// The feature on the other device, and the session it sees this side as.
  late Feature peer;
  late LinkedSession peerSession;

  bool open = true;

  /// Requests time out instead of being answered, like a phone that froze.
  bool unresponsive = false;
  final List<GeneratedMessage> pushes = [];
  final Map<Int64, ErrorCode> errors = {};
  int _nextId = 1;

  @override
  bool get isClosed => !open;

  @override
  DeviceInfo? get remoteDevice => DeviceInfo(id: remoteDeviceId, name: name);

  @override
  bool supports(String featureId) => featureId == MessagesFeature.featureId;

  @override
  FeatureSupport? remoteFeature(String featureId) => switch (supports(
    featureId,
  )) {
    true => FeatureSupport(id: featureId, flags: flags),
    false => null,
  };

  @override
  Future<void> send(String feature, GeneratedMessage message) async {
    if (!open) {
      throw const SessionClosedException();
    }

    pushes.add(message);
    await peer.onEnvelope(peerSession, _envelopeOf(message));
  }

  @override
  Future<T> call<T extends GeneratedMessage>(
    String feature,
    GeneratedMessage message,
    T Function() create, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!open) {
      throw const SessionClosedException();
    }

    if (unresponsive) {
      throw TimeoutException('no answer');
    }

    final envelope = _envelopeOf(message, expectsReply: true);
    final reply = await peer.onEnvelope(peerSession, envelope);
    if (reply == null) {
      final code = peerSession.errors[envelope.id] ?? .ERROR_CODE_UNSUPPORTED;
      throw RemoteErrorException(code, '');
    }

    final decoded = unpackPayload(
      type: reply.payloadType,
      payload: reply.toPayload(),
      create: create,
    );
    if (decoded == null) {
      throw RemoteErrorException(.ERROR_CODE_INVALID, reply.payloadType);
    }

    return decoded;
  }

  @override
  Future<void> replyError(
    Envelope request,
    ErrorCode code, [
    String message = '',
  ]) async => errors[request.id] = code;

  Envelope _envelopeOf(GeneratedMessage message, {bool expectsReply = false}) =>
      Envelope(
        id: Int64(_nextId++),
        feature: MessagesFeature.featureId,
        type: message.payloadType,
        payload: message.toPayload(),
        expectsReply: expectsReply,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Just enough of the engine for the feature: settings and sessions.
class FakeHost implements FeatureHost {
  FakeHost([Map<String, Object?>? settings])
    : settings = MemorySettingsStore(settings);

  @override
  final MemorySettingsStore settings;

  @override
  List<Session> sessions = [];

  @override
  Session? sessionFor(String deviceId) {
    for (final session in sessions) {
      if (session.remoteDeviceId == deviceId && !session.isClosed) {
        return session;
      }
    }

    return null;
  }

  @override
  Stream<List<Session>> get sessionChanges => const Stream.empty();

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A phone and a computer connected through [LinkedSession]s.
class PhoneAndComputer {
  PhoneAndComputer._(
    this.source,
    this.phone,
    this.computer,
    this.phoneHost,
    this.computerHost,
    this.store,
  );

  static const phoneId = 'pixelpixelpixelp';
  static const computerId = 'macbookmacbookma';

  static Future<PhoneAndComputer> start({
    FakeSmsSource? source,
    bool enabled = true,
    MemoryCacheStore? store,
    DateTime Function()? clock,
  }) async {
    final sms = source ?? FakeSmsSource();
    final cacheStore = store ?? MemoryCacheStore();
    final phoneHost = FakeHost({MessagesSettings.enabledKey: enabled});
    final computerHost = FakeHost();
    final phone = MessagesFeature(source: sms, clock: clock);
    final computer = MessagesFeature(cacheStore: cacheStore, clock: clock);
    await phone.start(phoneHost);
    await computer.start(computerHost);
    return PhoneAndComputer._(
      sms,
      phone,
      computer,
      phoneHost,
      computerHost,
      cacheStore,
    );
  }

  final FakeSmsSource source;
  final MessagesFeature phone;
  final MessagesFeature computer;
  final FakeHost phoneHost;
  final FakeHost computerHost;
  final MemoryCacheStore store;

  /// What the computer holds as its session to the phone.
  LinkedSession? toPhone;

  /// What the phone holds as its session to the computer.
  LinkedSession? toComputer;

  MessageLibrary get library => computer.library;

  /// Connects both sides and waits for the first sync.
  Future<void> connect() async {
    final toPhone = LinkedSession(
      phoneId,
      name: 'Pixel',
      flags: const [MessagesFeature.sourceFlag],
    );
    final toComputer = LinkedSession(
      computerId,
      name: 'MacBook',
      flags: const [MessagesFeature.receiveFlag],
    );
    toPhone
      ..peer = phone
      ..peerSession = toComputer;
    toComputer
      ..peer = computer
      ..peerSession = toPhone;
    this.toPhone = toPhone;
    this.toComputer = toComputer;
    computerHost.sessions = [toPhone];
    phoneHost.sessions = [toComputer];

    phone.onSessionOpened(toComputer);
    computer.onSessionOpened(toPhone);
    await settle();
  }

  Future<void> disconnect() async {
    final toPhone = this.toPhone;
    final toComputer = this.toComputer;
    if (toPhone == null || toComputer == null) {
      return;
    }

    toPhone.open = false;
    toComputer.open = false;
    computerHost.sessions = [];
    phoneHost.sessions = [];
    phone.onSessionClosed(toComputer);
    computer.onSessionClosed(toPhone);
    await settle();
  }

  Future<void> stop() async {
    await phone.stop();
    await computer.stop();
  }
}

/// A [LocalNotifier] that records what it was asked to show.
class FakeNotifier implements LocalNotifier {
  final Map<String, LocalNotice> shown = {};
  final List<LocalNotice> history = [];
  final List<String> cancelled = [];
  final StreamController<NoticeResponse> _responses = .broadcast(sync: true);

  void respond(NoticeResponse response) => _responses.add(response);

  @override
  Future<void> show(LocalNotice notice) async {
    shown[notice.id] = notice;
    history.add(notice);
  }

  @override
  Future<void> cancel(String id) async {
    shown.remove(id);
    cancelled.add(id);
  }

  @override
  Stream<NoticeResponse> get responses => _responses.stream;
}

/// A conversation as the phone reports it.
Conversation conversationOf(
  int threadId, {
  required int lastDateMs,
  String name = 'Alex',
  String address = '+15550001',
  String snippet = 'Hi',
  int unread = 0,
  List<Participant>? participants,
}) {
  final people = participants ?? [Participant(address: address, name: name)];
  return Conversation(
    threadId: Int64(threadId),
    participants: people,
    snippet: snippet,
    lastDateMs: Int64(lastDateMs),
    unreadCount: unread,
    isGroup: people.length > 1,
  );
}

/// A text as the phone reports it.
Message messageOf(
  String id, {
  required int threadId,
  required int dateMs,
  String body = 'Hello',
  MessageKind kind = .MESSAGE_KIND_INBOX,
  String sender = '+15550001',
  bool read = true,
  List<Attachment> attachments = const [],
}) => Message(
  id: id,
  threadId: Int64(threadId),
  senderAddress: switch (kind) {
    .MESSAGE_KIND_INBOX => sender,
    _ => '',
  },
  body: body,
  dateMs: Int64(dateMs),
  kind: kind,
  read: read,
  attachments: attachments,
);

/// Lets queued stream events and futures run.
Future<void> settle() async {
  for (var round = 0; round < 5; round++) {
    await Future<void>.delayed(Duration.zero);
  }
}
