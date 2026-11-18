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
    final isSending = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.isSending,
    );
    final result = context.select<ClipboardViewModel, ClipSendResult?>(
      (viewModel) => viewModel.lastResult,
    );
    final needsManualSend = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.needsManualSend,
    );
    final offersBackgroundSend = context.select<ClipboardViewModel, bool>(
      (viewModel) => viewModel.offersBackgroundSend,
    );
    final viewModel = context.read<ClipboardViewModel>();
    final l10n = context.clipboardL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final canCopy =
        latest != null &&
        latest.direction == .received &&
        !latest.onClipboard &&
        latest.hasContent;
    final limit = switch (access) {
      .onRequest => l10n.limitIos,
      _ => switch (offersBackgroundSend) {
        true => l10n.limitAndroidPowerReady,
        false => l10n.limitAndroid,
      },
    };

    return MinuteTicker(
      builder: (context, now) => FeatureCard(
        icon: LucideIcons.clipboard,
        title: l10n.title,
        subtitle: _subtitle(l10n, latest, now, needsManualSend),
        children: [
          if (latest != null) ClipPreview(entry: latest),
          if (latest != null && needsManualSend) Spacing.v8,
          if (needsManualSend)
            Text(
              limit,
              style: typography.caption1.copyWith(color: palette.mutedText),
            ),
          if (needsManualSend && result != null) ...[
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
        actions: [
          if (canCopy)
            Button(
              variant: .secondary,
              label: l10n.copy,
              icon: Icon(LucideIcons.copy, size: Spacing.d16),
              onPressed: () => viewModel.copy(latest),
            ),
          if (offersBackgroundSend)
            Button(
              variant: .secondary,
              label: l10n.sendInBackground,
              icon: Icon(LucideIcons.zap, size: Spacing.d16),
              onPressed: () => viewModel.setBackgroundSend(true),
            ),
          if (needsManualSend)
            Button(
              variant: .primary,
              label: l10n.sendClipboard,
              icon: Icon(LucideIcons.send, size: Spacing.d16),
              enable: !isSending,
              onPressed: () => viewModel.sendClipboard(),
            ),
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
