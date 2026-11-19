import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/ui/widgets/bubble.dart';
import 'package:protocol/messages.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One text in a thread: the sender in groups, pictures, the words, the
/// time, and whether it failed or still waits.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    this.senderName,
    this.onOpenImage,
  });

  final Message message;
  final String time;

  /// Shown above received texts in group conversations.
  final String? senderName;
  final void Function(Attachment attachment)? onOpenImage;

  bool get mine => message.kind != .MESSAGE_KIND_INBOX;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;
    final textColor = switch (mine) {
      true => palette.background,
      false => palette.text,
    };
    final status = switch (message.kind) {
      .MESSAGE_KIND_FAILED => l10n.kindFailed,
      .MESSAGE_KIND_QUEUED => l10n.kindQueued,
      .MESSAGE_KIND_OUTBOX => l10n.kindOutbox,
      _ => null,
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d2),
      child: Column(
        crossAxisAlignment: switch (mine) {
          true => .end,
          false => .start,
        },
        children: [
          if (senderName case final name?)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: Spacing.d12,
                bottom: Spacing.d2,
              ),
              child: Text(
                name,
                style: typography.caption2.copyWith(color: palette.mutedText),
              ),
            ),
          Bubble(
            mine: mine,
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                for (final attachment in message.attachments)
                  _AttachmentView(
                    attachment: attachment,
                    color: textColor,
                    onOpen: onOpenImage,
                  ),
                if (message.body.isNotEmpty)
                  Text(
                    message.body,
                    style: typography.body2.copyWith(color: textColor),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.d8,
              vertical: Spacing.d2,
            ),
            child: Text(
              switch (status) {
                final String label => '$time · $label',
                null => time,
              },
              style: typography.caption2.copyWith(
                color: switch (message.kind) {
                  .MESSAGE_KIND_FAILED => palette.danger,
                  _ => palette.mutedText,
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentView extends StatelessWidget {
  const _AttachmentView({
    required this.attachment,
    required this.color,
    required this.onOpen,
  });

  final Attachment attachment;
  final Color color;
  final void Function(Attachment attachment)? onOpen;

  @override
  Widget build(BuildContext context) {
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;
    final thumbnail = attachment.thumbnailJpeg;

    if (thumbnail.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: Spacing.d4),
        child: Tappable(
          tooltip: l10n.photo,
          onTap: switch (onOpen) {
            final open? => () => open(attachment),
            null => null,
          },
          child: ClipRSuperellipse(
            borderRadius: Corners.radius(Spacing.d10),
            child: Image.memory(
              Uint8List.fromList(thumbnail),
              width: Spacing.d200,
              fit: .cover,
              gaplessPlayback: true,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d4),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(LucideIcons.paperclip, size: Spacing.d14, color: color),
          Spacing.h6,
          Flexible(
            child: Text(
              switch (attachment.name.isEmpty) {
                true => l10n.attachmentLabel(attachment),
                false => attachment.name,
              },
              style: typography.caption1.copyWith(color: color),
              overflow: .ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
