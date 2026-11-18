import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/models/models.dart';
import 'package:messages/ui/widgets/avatar.dart';
import 'package:messages/ui/widgets/time_labels.dart';
import 'package:protocol/messages.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One conversation in the list: who, the last text, when, and unread.
class ConversationRow extends StatelessWidget {
  const ConversationRow({
    super.key,
    required this.conversation,
    required this.selected,
    required this.labels,
    required this.onTap,
  });

  final Conversation conversation;
  final bool selected;
  final TimeLabels labels;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;
    final unread = conversation.unreadCount;
    final snippet = switch (conversation.snippet.isEmpty) {
      true => l10n.attachment,
      false => conversation.snippet,
    };
    final at = DateTime.fromMillisecondsSinceEpoch(
      conversation.lastDateMs.toInt(),
    );
    final titleStyle = switch (unread > 0) {
      true => typography.base1.copyWith(
        color: palette.text,
        fontWeight: .w700,
      ),
      false => typography.base1.copyWith(color: palette.text),
    };

    return Tappable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.d8,
          vertical: Spacing.d8,
        ),
        decoration: BoxDecoration(
          color: switch (selected) {
            true => palette.surface,
            false => null,
          },
          borderRadius: BorderRadius.circular(Spacing.d10),
        ),
        child: Row(
          children: [
            Avatar(participants: conversation.participants, size: Spacing.d40),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    conversation.title,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                  Spacing.vertical(Spacing.d2),
                  Text(
                    snippet,
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                    maxLines: 2,
                    overflow: .ellipsis,
                  ),
                ],
              ),
            ),
            Spacing.h8,
            Column(
              crossAxisAlignment: .end,
              children: [
                Text(
                  labels.short(at),
                  style: typography.caption2.copyWith(
                    color: palette.mutedText,
                  ),
                ),
                if (unread > 0) ...[
                  Spacing.v4,
                  _UnreadBadge(count: unread),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Container(
      constraints: BoxConstraints(minWidth: Spacing.d20),
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d6,
        vertical: Spacing.d1,
      ),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(Spacing.d10),
      ),
      alignment: .center,
      child: Text(
        '$count',
        style: typography.caption2.copyWith(color: palette.background),
      ),
    );
  }
}
