import 'package:messages/models/models.dart';
import 'package:protocol/messages.dart';

/// Where a phone reads and sends its own texts. Only Android has one.
abstract interface class SmsSource {
  /// Fires when texts change, after [startWatching].
  Stream<void> get changes;

  Future<SmsAccess> access();

  /// Asks the person for SMS and contacts access, with the system dialog.
  Future<SmsAccess> requestAccess();

  /// Opens the app's settings page. False when it could not be opened.
  Future<bool> openAppSettings();

  Future<ConversationPage> listConversations({
    int beforeDateMs = 0,
    required int limit,
  });

  Future<List<Conversation>> conversationsById(List<int> threadIds);

  Future<MessagePage> listMessages(
    int threadId, {
    int beforeDateMs = 0,
    List<String> skipIds = const [],
    required int limit,
  });

  /// Texts of every conversation dated after [sinceDateMs], newest first.
  Future<List<Message>> recentMessages({
    required int sinceDateMs,
    required int limit,
  });

  Future<AttachmentData?> fetchAttachment(String messageId, String partId);

  Future<SendResult> send(SendText request);

  /// Whether the phone marked it read. Android allows it only for the
  /// default messaging app.
  Future<bool> markRead(int threadId);

  Future<void> startWatching();

  Future<void> stopWatching();
}
