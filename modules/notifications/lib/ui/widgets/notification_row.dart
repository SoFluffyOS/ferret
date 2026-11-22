import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/models/models.dart';
import 'package:notifications/ui/widgets/app_icon.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A mirrored notification in one compact row, with a dismiss button and,
/// when the phone's app takes one, a reply field that opens under it.
class NotificationRow extends StatefulWidget {
  const NotificationRow({
    super.key,
    required this.notification,
    required this.dismissLabel,
    required this.onDismiss,
    this.onReply,
  });

  final MirroredNotification notification;
  final String dismissLabel;
  final VoidCallback onDismiss;

  /// Sends a reply; true when it reached the phone.
  final Future<bool> Function(String text)? onReply;

  @override
  State<NotificationRow> createState() => _NotificationRowState();
}

enum _ReplyState { closed, open, sending, sent, failed }

class _NotificationRowState extends State<NotificationRow> {
  final TextEditingController _controller = .new();
  final FocusNode _focus = .new();
  _ReplyState _reply = .closed;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;
    final muted = typography.caption1.copyWith(color: palette.mutedText);
    final time = ClockText.timeOfDay(
      Localizations.localeOf(context).toLanguageTag(),
      notification.postedAt,
    );
    final canReply = widget.onReply != null && notification.canReply;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d4),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          AppIcon(png: notification.appIcon, size: Spacing.d20),
          Spacing.h8,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  '${notification.heading} · $time',
                  style: typography.caption1.copyWith(color: palette.text),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
                if (notification.text.isNotEmpty)
                  Text(
                    notification.text,
                    style: muted,
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                ...switch (_reply) {
                  .closed => const <Widget>[],
                  .sent => [Text(l10n.replySent, style: muted)],
                  .open || .sending => [Spacing.v4, _field(context)],
                  .failed => [
                    Spacing.v4,
                    _field(context),
                    Spacing.v4,
                    Text(l10n.replyFailedTitle, style: muted),
                  ],
                },
              ],
            ),
          ),
          if (canReply)
            _iconButton(
              context,
              icon: LucideIcons.reply,
              tooltip: l10n.reply,
              onTap: _toggleReply,
            ),
          _iconButton(
            context,
            icon: LucideIcons.x,
            tooltip: widget.dismissLabel,
            onTap: widget.onDismiss,
          ),
        ],
      ),
    );
  }

  Widget _field(BuildContext context) {
    final l10n = context.notificationsL10n;

    return Row(
      crossAxisAlignment: .center,
      children: [
        Expanded(
          child: InputText(
            controller: _controller,
            focusNode: _focus,
            hintText: l10n.replyHint,
            maxLines: 1,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => unawaited(_send()),
          ),
        ),
        Spacing.h8,
        Button(
          mainAxisSize: .min,
          variant: .secondary,
          label: l10n.reply,
          enable: _reply != .sending,
          onPressed: () => unawaited(_send()),
        ),
      ],
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) => Tappable(
    tooltip: tooltip,
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.all(Spacing.d4),
      child: Icon(icon, size: Spacing.d14, color: context.palette.mutedText),
    ),
  );

  void _toggleReply() {
    final opening = switch (_reply) {
      .closed || .sent => true,
      _ => false,
    };
    setState(
      () => _reply = switch (opening) {
        true => .open,
        false => .closed,
      },
    );
    if (opening) {
      _focus.requestFocus();
    }
  }

  Future<void> _send() async {
    final onReply = widget.onReply;
    final text = _controller.text;
    if (onReply == null || text.trim().isEmpty || _reply == .sending) {
      return;
    }

    setState(() => _reply = .sending);
    final sent = await onReply(text);
    if (!mounted) {
      return;
    }

    if (sent) {
      _controller.clear();
    }

    setState(
      () => _reply = switch (sent) {
        true => .sent,
        false => .failed,
      },
    );
  }
}
