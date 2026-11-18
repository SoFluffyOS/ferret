import 'package:feature_kit/feature_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/services.dart';
import 'package:protocol/messages.dart';

const _maxLines = 3;

/// Messages' lines in Activity on a computer: the newest text of each
/// unread conversation on a paired phone, newest first, with Reply. At most
/// three, so a busy phone doesn't fill Home.
List<ActivityItem> messagesActivity({
  required MessagesLocalizations l10n,
  required MessageLibrary library,
  required String Function(String deviceId) deviceName,
  required bool Function(String deviceId) isPaired,
  required void Function(String deviceId, int threadId) onOpen,
}) {
  final unread =
      [
        for (final deviceId in library.deviceIds)
          if (isPaired(deviceId))
            for (final conversation in library.cache(deviceId).conversations)
              if (conversation.unreadCount > 0)
                (deviceId: deviceId, conversation: conversation),
      ]..sort(
        (first, second) => second.conversation.lastDateMs.compareTo(
          first.conversation.lastDateMs,
        ),
      );

  return [
    for (final (:deviceId, :conversation) in unread.take(_maxLines))
      _line(
        l10n: l10n,
        conversation: conversation,
        deviceName: deviceName(deviceId),
        onOpen: () => onOpen(deviceId, conversation.threadId.toInt()),
        id: 'messages.$deviceId/${conversation.threadId}',
        deviceId: deviceId,
      ),
  ];
}

ActivityItem _line({
  required MessagesLocalizations l10n,
  required Conversation conversation,
  required String deviceName,
  required void Function() onOpen,
  required String id,
  required String deviceId,
}) => ActivityItem(
  id: id,
  deviceId: deviceId,
  icon: LucideIcons.messageSquare,
  title: l10n.activityTitle(conversation.title, deviceName),
  detail: switch (conversation.snippet.isEmpty) {
    true => l10n.attachment,
    false => conversation.snippet,
  },
  at: DateTime.fromMillisecondsSinceEpoch(conversation.lastDateMs.toInt()),
  actions: [ActivityAction(label: l10n.replyAction, onPressed: onOpen)],
  onTap: onOpen,
);
