import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/models/models.dart';
import 'package:clipboard/ui/widgets/widgets.dart';
import 'package:clipboard/view_models/clipboard_view_model.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_clipboard/ferret_clipboard.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card: the last clip and where it went, and on phones a Send
/// clipboard button with the reason it is needed.
class ClipboardCardFrame extends StatelessWidget {
  const ClipboardCardFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final latest = context.select<ClipboardViewModel, ClipEntry?>(
      (viewModel) => viewModel.latest,
    );
    final access = context.select<ClipboardViewModel, ClipboardAccess>(
      (viewModel) => viewModel.access,
    );
    final l10n = context.clipboardL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final needsManualSend = !access.watchesOtherApps;
    final canCopy =
        latest != null &&
        latest.direction == .received &&
        !latest.onClipboard &&
        latest.hasContent;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.clipboard,
                size: Spacing.d20,
                color: palette.text,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      l10n.title,
                      style: typography.base1.copyWith(color: palette.text),
                    ),
                    Spacing.vertical(Spacing.d2),
                    MinuteTicker(
                      builder: (context, now) => Text(
                        _subtitle(l10n, latest, now, needsManualSend),
                        style: typography.caption1.copyWith(
                          color: palette.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (latest != null) ...[Spacing.v12, ClipPreview(entry: latest)],
          if (canCopy) ...[
            Spacing.v8,
            Button(
              variant: .secondary,
              label: l10n.copy,
              icon: Icon(LucideIcons.copy, size: Spacing.d16),
              onPressed: () => context.read<ClipboardViewModel>().copy(latest),
            ),
          ],
          if (needsManualSend) _ManualSend(access: access),
        ],
      ),
    );
  }

  String _subtitle(
    ClipboardLocalizations l10n,
    ClipEntry? latest,
    DateTime now,
    bool needsManualSend,
  ) {
    if (latest != null) {
      return l10n.statusOf(latest, now);
    }

    if (needsManualSend) {
      return l10n.cardEmptyManual;
    }

    return l10n.cardEmpty;
  }
}

class _ManualSend extends StatelessWidget {
  const _ManualSend({required this.access});

  final ClipboardAccess access;

  @override
  Widget build(BuildContext context) {
    final isSending = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.isSending,
    );
    final result = context.select<ClipboardViewModel, ClipSendResult?>(
      (viewModel) => viewModel.lastResult,
    );
    final l10n = context.clipboardL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final limit = switch (access) {
      .onRequest => l10n.limitIos,
      _ => l10n.limitAndroid,
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Spacing.v12,
        Text(
          limit,
          style: typography.caption1.copyWith(color: palette.mutedText),
        ),
        Spacing.v8,
        Button(
          variant: .primary,
          label: l10n.sendClipboard,
          icon: Icon(LucideIcons.send, size: Spacing.d16),
          enable: !isSending,
          onPressed: () => context.read<ClipboardViewModel>().sendClipboard(),
        ),
        if (result != null) ...[
          Spacing.v6,
          Text(
            l10n.resultOf(result),
            style: typography.caption1.copyWith(
              color: switch (result) {
                .sent => palette.success,
                _ => palette.mutedText,
              },
            ),
          ),
        ],
      ],
    );
  }
}
