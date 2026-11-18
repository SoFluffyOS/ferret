import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/models/models.dart';
import 'package:messages/ui/widgets/widgets.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:protocol/messages.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One conversation: bubbles grouped by day, newest at the bottom, older
/// texts loading as the person scrolls up, and the composer.
class ThreadFrame extends StatelessWidget {
  const ThreadFrame({
    super.key,
    required this.phoneName,
    required this.onOpenImage,
    this.showHeader = true,
  });

  final String phoneName;
  final bool showHeader;
  final void Function(Message message, Attachment attachment) onOpenImage;

  static const _loadAheadPixels = 400.0;

  @override
  Widget build(BuildContext context) {
    final conversation = context.select<ThreadViewModel, Conversation?>(
      (viewModel) => viewModel.conversation,
    );
    final messages = context.select<ThreadViewModel, List<Message>>(
      (viewModel) => viewModel.messages,
    );
    final pending = context.select<ThreadViewModel, List<PendingMessage>>(
      (viewModel) => viewModel.pending,
    );
    final loadingOlder = context.select<ThreadViewModel, bool>(
      (viewModel) => viewModel.loadingOlder,
    );
    final loadFailed = context.select<ThreadViewModel, bool>(
      (viewModel) => viewModel.loadFailed,
    );
    final block = context.select<ThreadViewModel, ComposerBlock>(
      (viewModel) => viewModel.composerBlock,
    );
    final viewModel = context.read<ThreadViewModel>();
    final l10n = context.messagesL10n;
    final labels = TimeLabels(l10n, l10n.localeName, DateTime.now());
    final items = _itemsOf(
      messages: messages,
      pending: pending,
      conversation: conversation,
      labels: labels,
      viewModel: viewModel,
    ).reversed.toList();

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (showHeader && conversation != null)
          _Header(conversation: conversation),
        if (loadFailed)
          Padding(
            padding: EdgeInsets.all(Spacing.d8),
            child: StatusBanner(
              text: l10n.loadFailed(phoneName),
              actionLabel: l10n.retry,
              onAction: viewModel.loadNewest,
            ),
          ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < _loadAheadPixels) {
                unawaited(viewModel.loadOlder());
              }

              return false;
            },
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.symmetric(
                horizontal: Spacing.d12,
                vertical: Spacing.d8,
              ),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index < items.length) {
                  return items[index];
                }

                return _OlderFooter(loading: loadingOlder);
              },
            ),
          ),
        ),
        Composer(
          blockedReason: switch (block) {
            .none => null,
            .offline => l10n.composerOffline(phoneName),
            .group => l10n.composerGroup,
            .noSend => l10n.composerNoSend,
          },
          onSend: viewModel.send,
        ),
      ],
    );
  }

  List<Widget> _itemsOf({
    required List<Message> messages,
    required List<PendingMessage> pending,
    required Conversation? conversation,
    required TimeLabels labels,
    required ThreadViewModel viewModel,
  }) {
    final items = <Widget>[];
    final isGroup = conversation?.isGroup ?? false;
    DateTime? previousDay;
    String? previousSender;

    for (final message in messages) {
      final at = DateTime.fromMillisecondsSinceEpoch(message.dateMs.toInt());
      if (previousDay == null || !TimeLabels.sameDay(previousDay, at)) {
        items.add(DayDivider(label: labels.day(at)));
        previousSender = null;
      }

      previousDay = at;
      final received = message.kind == .MESSAGE_KIND_INBOX;
      final showSender =
          isGroup && received && message.senderAddress != previousSender;
      items.add(
        MessageBubble(
          key: ValueKey(message.id),
          message: message,
          time: labels.time(at),
          senderName: switch (showSender) {
            true =>
              conversation?.nameFor(message.senderAddress) ??
                  message.senderAddress,
            false => null,
          },
          onOpenImage: (attachment) => onOpenImage(message, attachment),
        ),
      );
      previousSender = switch (received) {
        true => message.senderAddress,
        false => null,
      };
    }

    for (final message in pending) {
      items.add(
        PendingBubble(
          key: ValueKey(message.id),
          message: message,
          onRetry: () => unawaited(viewModel.retry(message)),
          onDiscard: () => viewModel.discard(message),
        ),
      );
    }

    return items;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final numbers = [
      for (final participant in conversation.participants)
        if (participant.name.isNotEmpty) participant.address,
    ].join(', ');

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d12,
        vertical: Spacing.d8,
      ),
      child: Row(
        children: [
          Avatar(participants: conversation.participants, size: Spacing.d32),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  conversation.title,
                  style: typography.base1.copyWith(color: palette.text),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
                if (numbers.isNotEmpty)
                  Text(
                    numbers,
                    style: typography.caption2.copyWith(
                      color: palette.mutedText,
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OlderFooter extends StatelessWidget {
  const _OlderFooter({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (!loading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.all(Spacing.d12),
      child: Text(
        context.messagesL10n.loadingOlder,
        textAlign: .center,
        style: context.fluffyTheme.typography.caption1.copyWith(
          color: context.palette.mutedText,
        ),
      ),
    );
  }
}
