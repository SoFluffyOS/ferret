import 'package:pigeon/pigeon.dart';

// Regenerate with `fvm dart run pigeon --input pigeon/messages.dart` from the
// package folder. Reading and sending SMS is Android only.
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_messages',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/io/sofluffy/ferret_messages/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_messages'),
  ),
)
/// What Android lets this app do with messages and contacts.
class PlatformAccess {
  PlatformAccess({
    required this.hasTelephony,
    required this.canRead,
    required this.canSend,
    required this.canReadContacts,
    required this.blocked,
  });

  /// The device can send and receive SMS at all.
  bool hasTelephony;

  /// READ_SMS is granted.
  bool canRead;

  /// SEND_SMS is granted.
  bool canSend;

  /// READ_CONTACTS is granted.
  bool canReadContacts;

  /// The person denied SMS access for good ("Don't ask again"), so only the
  /// app's settings page can grant it now.
  bool blocked;
}

class PlatformParticipant {
  PlatformParticipant({
    required this.address,
    required this.name,
    this.avatarJpeg,
  });

  String address;

  /// The contact's name, or empty.
  String name;

  /// A small JPEG of the contact's photo.
  Uint8List? avatarJpeg;
}

class PlatformConversation {
  PlatformConversation({
    required this.threadId,
    required this.participants,
    required this.snippet,
    required this.lastDateMs,
    required this.unreadCount,
    required this.isGroup,
  });

  int threadId;
  List<PlatformParticipant> participants;
  String snippet;
  int lastDateMs;
  int unreadCount;
  bool isGroup;
}

class PlatformConversationPage {
  PlatformConversationPage({
    required this.conversations,
    required this.hasMore,
  });

  List<PlatformConversation> conversations;
  bool hasMore;
}

enum PlatformMessageKind { inbox, sent, outbox, failed, queued }

class PlatformAttachment {
  PlatformAttachment({
    required this.partId,
    required this.mime,
    required this.size,
    required this.name,
    this.thumbnailJpeg,
  });

  String partId;
  String mime;
  int size;
  String name;

  /// A small JPEG preview for images.
  Uint8List? thumbnailJpeg;
}

class PlatformMessage {
  PlatformMessage({
    required this.id,
    required this.threadId,
    required this.senderAddress,
    required this.body,
    required this.dateMs,
    required this.kind,
    required this.attachments,
    required this.read,
  });

  /// `sms:<row id>` or `mms:<row id>`.
  String id;
  int threadId;

  /// Empty for messages sent from this phone.
  String senderAddress;
  String body;
  int dateMs;
  PlatformMessageKind kind;
  List<PlatformAttachment> attachments;
  bool read;
}

class PlatformMessagePage {
  PlatformMessagePage({required this.messages, required this.hasMore});

  /// Newest first.
  List<PlatformMessage> messages;
  bool hasMore;
}

class PlatformAttachmentData {
  PlatformAttachmentData({required this.mime, required this.data});

  String mime;
  Uint8List data;
}

enum PlatformSendFailure {
  none,
  noAccess,
  noRecipient,
  group,
  noService,
  timeout,
  other,
}

class PlatformSendResult {
  PlatformSendResult({required this.failure, required this.threadId});

  /// [PlatformSendFailure.none] when the radio confirmed the send.
  PlatformSendFailure failure;

  /// The thread the message went to, or 0 when unknown.
  int threadId;
}

@HostApi()
abstract class MessagesHostApi {
  PlatformAccess access();

  /// Shows Android's permission dialog for SMS and contacts, and returns
  /// what was granted.
  @async
  PlatformAccess requestAccess();

  /// Opens this app's App info page, where denied permissions can be turned
  /// on. Returns false when no such page could be opened.
  bool openAppSettings();

  /// Conversations whose last message is older than [beforeDateMs] (0 for
  /// the newest), most recent first.
  @async
  PlatformConversationPage listConversations(int beforeDateMs, int limit);

  /// The conversations with these thread ids that still exist.
  @async
  List<PlatformConversation> conversationsById(List<int> threadIds);

  /// Messages of [threadId] at or before [beforeDateMs] (0 for the newest),
  /// leaving out [skipIds], newest first.
  @async
  PlatformMessagePage listMessages(
    int threadId,
    int beforeDateMs,
    List<String> skipIds,
    int limit,
  );

  /// Messages of every thread dated after [sinceDateMs], newest first.
  @async
  List<PlatformMessage> recentMessages(int sinceDateMs, int limit);

  /// An MMS part in full, or null when it is gone or too large.
  @async
  PlatformAttachmentData? fetchAttachment(String messageId, String partId);

  /// Sends [text] as SMS to the thread's address, or to [addresses] when
  /// [threadId] is 0, and waits for the radio to confirm.
  @async
  PlatformSendResult send(int threadId, List<String> addresses, String text);

  /// Marks [threadId] as read. Android ignores this unless Ferret is the
  /// default messaging app; returns whether it took effect.
  @async
  bool markRead(int threadId);

  /// Starts reporting changes to messages through
  /// [MessagesFlutterApi.onChanged].
  void startWatching();

  void stopWatching();
}

@FlutterApi()
abstract class MessagesFlutterApi {
  /// Messages changed on the phone, such as a new SMS. Bursts are merged.
  void onChanged();
}
