import 'dart:async';
import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/services/services.dart';
import 'package:messages/ui/frames/frames.dart';
import 'package:messages/ui/pages/image_page.dart';
import 'package:messages/ui/pages/page_header.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:protocol/messages.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A phone's texts on a computer: the conversation list and one thread side
/// by side on wide windows, one at a time on narrow ones.
class MessagesPage extends StatelessWidget {
  const MessagesPage({
    super.key,
    required this.library,
    required this.deviceId,
    required this.phoneName,
    this.initialThreadId,
    this.onThreadOpened,
  });

  final MessageLibrary library;
  final String deviceId;
  final String phoneName;
  final int? initialThreadId;

  /// Called when a thread shows, such as to clear its notice.
  final void Function(int threadId)? onThreadOpened;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => InboxViewModel(
      library: library,
      deviceId: deviceId,
      phoneName: phoneName,
      initialThreadId: initialThreadId,
    ),
    child: _MessagesLayout(onThreadOpened: onThreadOpened),
  );
}

class _MessagesLayout extends StatelessWidget {
  const _MessagesLayout({required this.onThreadOpened});

  final void Function(int threadId)? onThreadOpened;

  @override
  Widget build(BuildContext context) {
    final selected = context.select<InboxViewModel, int?>(
      (viewModel) => viewModel.selectedThreadId,
    );
    final viewModel = context.read<InboxViewModel>();
    final l10n = context.messagesL10n;
    final canPop = Navigator.of(context).canPop();
    final isUnderToolbar = PaneToolbarScope.titleOf(context) != null;

    return ColoredBox(
      color: context.palette.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= Spacing.d360 * 2;
            final showsThreadAlone = !wide && selected != null;
            final VoidCallback? onBack = switch ((showsThreadAlone, canPop)) {
              (true, _) => () => viewModel.select(null),
              (false, true) => () => Navigator.of(context).maybePop(),
              _ => null,
            };

            return Column(
              crossAxisAlignment: .stretch,
              children: [
                // A window's toolbar already says "Messages · Pixel 9".
                if (onBack != null || !isUnderToolbar)
                  PageHeader(
                    title: l10n.cardTitle(viewModel.phoneName),
                    backLabel: l10n.back,
                    onBack: onBack,
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Spacing.d12),
                  child: const StatusBannerFrame(),
                ),
                Expanded(
                  child: switch ((wide, selected)) {
                    (true, _) => Row(
                      crossAxisAlignment: .stretch,
                      children: [
                        SizedBox(
                          width: Spacing.d320,
                          child: ConversationListFrame(
                            onOpen: viewModel.select,
                          ),
                        ),
                        Expanded(
                          child: _ThreadPane(
                            threadId: selected,
                            onThreadOpened: onThreadOpened,
                          ),
                        ),
                      ],
                    ),
                    (false, final int threadId) => _ThreadPane(
                      threadId: threadId,
                      onThreadOpened: onThreadOpened,
                    ),
                    (false, null) => ConversationListFrame(
                      onOpen: viewModel.select,
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ThreadPane extends StatelessWidget {
  const _ThreadPane({required this.threadId, required this.onThreadOpened});

  final int? threadId;
  final void Function(int threadId)? onThreadOpened;

  @override
  Widget build(BuildContext context) {
    final inbox = context.read<InboxViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;
    final current = threadId;

    final hasConversations = context.select<InboxViewModel, bool>(
      (inbox) => inbox.conversations.isNotEmpty,
    );
    if (current == null && !hasConversations) {
      return const SizedBox.shrink();
    }

    if (current == null) {
      return Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(
              LucideIcons.messagesSquare,
              size: Spacing.d32,
              color: palette.mutedText,
            ),
            Spacing.v8,
            Text(
              l10n.pickConversation,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ],
        ),
      );
    }

    return ChangeNotifierProvider(
      key: ValueKey(current),
      create: (_) => ThreadViewModel(
        library: inbox.library,
        deviceId: inbox.deviceId,
        threadId: current,
        onOpened: () => onThreadOpened?.call(current),
      ),
      child: Builder(
        builder: (context) => ThreadFrame(
          phoneName: inbox.phoneName,
          onOpenImage: (message, attachment) =>
              _openImage(context, inbox.phoneName, message, attachment),
        ),
      ),
    );
  }

  void _openImage(
    BuildContext context,
    String phoneName,
    Message message,
    Attachment attachment,
  ) {
    final thread = context.read<ThreadViewModel>();
    final preview = switch (attachment.thumbnailJpeg.isEmpty) {
      true => null,
      false => Uint8List.fromList(attachment.thumbnailJpeg),
    };

    unawaited(
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => ImagePage(
            phoneName: phoneName,
            preview: preview,
            load: () => thread.fullImage(message, attachment),
          ),
        ),
      ),
    );
  }
}
