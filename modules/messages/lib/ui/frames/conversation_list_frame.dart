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

/// The phone's conversations, newest first, loading older ones near the end.
class ConversationListFrame extends StatelessWidget {
  const ConversationListFrame({super.key, required this.onOpen});

  final void Function(int threadId) onOpen;

  static const _loadAheadPixels = 400.0;

  @override
  Widget build(BuildContext context) {
    final conversations = context.select<InboxViewModel, List<Conversation>>(
      (viewModel) => viewModel.conversations,
    );
    final selected = context.select<InboxViewModel, int?>(
      (viewModel) => viewModel.selectedThreadId,
    );
    final loadingMore = context.select<InboxViewModel, bool>(
      (viewModel) => viewModel.loadingMore,
    );
    final readiness = context.select<InboxViewModel, PhoneReadiness>(
      (viewModel) => viewModel.phone.readiness,
    );
    final syncing = context.select<InboxViewModel, bool>(
      (viewModel) => viewModel.phone.syncing,
    );
    final viewModel = context.read<InboxViewModel>();
    final l10n = context.messagesL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final labels = TimeLabels(l10n, l10n.localeName, DateTime.now());
    final showEmpty = conversations.isEmpty && readiness == .ready && !syncing;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < _loadAheadPixels) {
          unawaited(viewModel.loadMore());
        }

        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.d8,
          vertical: Spacing.d4,
        ),
        itemCount: conversations.length + 1,
        itemBuilder: (context, index) {
          if (index < conversations.length) {
            final conversation = conversations[index];
            final threadId = conversation.threadId.toInt();
            return ConversationRow(
              key: ValueKey(threadId),
              conversation: conversation,
              selected: threadId == selected,
              labels: labels,
              onTap: () => onOpen(threadId),
            );
          }

          final footer = switch ((showEmpty, loadingMore)) {
            (true, _) => l10n.conversationsEmpty,
            (_, true) => l10n.loadingOlder,
            _ => l10n.rcsComputerNote,
          };
          return Padding(
            padding: EdgeInsets.all(Spacing.d16),
            child: Text(
              footer,
              textAlign: .center,
              style: typography.caption1.copyWith(color: palette.mutedText),
            ),
          );
        },
      ),
    );
  }
}
