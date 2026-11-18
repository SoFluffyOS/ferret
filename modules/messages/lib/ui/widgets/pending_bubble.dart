import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/models/models.dart';
import 'package:messages/ui/widgets/bubble.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A reply typed here: faded while the phone sends it, with the reason and
/// Retry when it failed.
class PendingBubble extends StatelessWidget {
  const PendingBubble({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onDiscard,
  });

  final PendingMessage message;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d2),
      child: Column(
        crossAxisAlignment: .end,
        children: [
          Bubble(
            mine: true,
            faded: true,
            child: Text(
              message.text,
              style: typography.body2.copyWith(color: palette.background),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.d8,
              vertical: Spacing.d2,
            ),
            child: switch (message.outcome) {
              final SendOutcome outcome when message.failed => _Failed(
                reason: '${l10n.notSent}. ${l10n.outcomeText(outcome)}',
                onRetry: onRetry,
                onDiscard: onDiscard,
              ),
              _ => Text(
                l10n.sending,
                style: typography.caption2.copyWith(color: palette.mutedText),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({
    required this.reason,
    required this.onRetry,
    required this.onDiscard,
  });

  final String reason;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;

    return Column(
      crossAxisAlignment: .end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Spacing.d360),
          child: Text(
            reason,
            textAlign: .end,
            style: typography.caption1.copyWith(color: palette.danger),
          ),
        ),
        Spacing.v4,
        Row(
          mainAxisSize: .min,
          children: [
            Button(variant: .ghost, label: l10n.discard, onPressed: onDiscard),
            Spacing.h8,
            Button(
              variant: .ghost,
              label: l10n.retrySend,
              onPressed: onRetry,
            ),
          ],
        ),
      ],
    );
  }
}
