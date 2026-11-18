import 'package:messages/l10n/generated/messages_localizations.dart';
import 'package:messages/models/models.dart';
import 'package:protocol/messages.dart';

/// Strings for messages and send outcomes, shared by widgets and notices.
extension MessageLabels on MessagesLocalizations {
  String attachmentLabel(Attachment file) {
    final mime = file.mime;
    if (mime.startsWith('image/')) {
      return photo;
    }

    if (mime.startsWith('video/')) {
      return video;
    }

    if (mime.startsWith('audio/')) {
      return audio;
    }

    if (mime.contains('vcard')) {
      return contactCard;
    }

    return attachment;
  }

  /// The text of [message], or what it carries when it has no text.
  String preview(Message message) {
    if (message.body.trim().isNotEmpty) {
      return message.body;
    }

    if (message.attachments.isEmpty) {
      return '';
    }

    return attachmentLabel(message.attachments.first);
  }

  String outcomeText(SendOutcome outcome) => switch (outcome) {
    .sent => '',
    .offline => outcomeOffline,
    .noAccess => outcomeNoAccess,
    .noRecipient => outcomeNoRecipient,
    .group => outcomeGroup,
    .noService => outcomeNoService,
    .timeout => outcomeTimeout,
    .failed => outcomeFailed,
  };
}
