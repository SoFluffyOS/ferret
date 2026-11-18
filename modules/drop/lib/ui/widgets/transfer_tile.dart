import 'package:drop/models/models.dart';
import 'package:drop/ui/widgets/transfer_action.dart';
import 'package:drop/ui/widgets/transfer_progress_bar.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One transfer: what it is, where it stands in plain words, its progress,
/// and what can be done with it.
class TransferTile extends StatelessWidget {
  const TransferTile({
    super.key,
    required this.transfer,
    required this.title,
    required this.status,
    required this.actions,
    this.speed,
    this.details = const [],
    this.onDismiss,
    this.dismissLabel = '',
  });

  final Transfer transfer;
  final String title;
  final String status;
  final String? speed;

  /// Extra lines under the status, such as who a LocalSend offer is from.
  final List<String> details;
  final List<TransferAction> actions;
  final VoidCallback? onDismiss;
  final String dismissLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final statusColor = switch (transfer.status) {
      TransferStatus.failed => palette.danger,
      TransferStatus.done => palette.success,
      _ => palette.mutedText,
    };
    final barColor = switch (transfer.status) {
      TransferStatus.verifying => palette.success,
      _ => palette.accent,
    };
    final icon = switch ((transfer.isText, transfer.isOutgoing)) {
      (true, _) => LucideIcons.messageSquareText,
      (false, true) => LucideIcons.arrowUpRight,
      (false, false) => LucideIcons.arrowDownLeft,
    };

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: Spacing.d2),
              child: Icon(icon, size: Spacing.d16, color: palette.text),
            ),
            Spacing.h8,
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: typography.base1.copyWith(color: palette.text),
                  ),
                  Spacing.vertical(Spacing.d2),
                  Text(
                    status,
                    style: typography.caption1.copyWith(color: statusColor),
                  ),
                  if (speed case final line?)
                    Text(
                      line,
                      style: typography.caption1.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  for (final detail in details)
                    Text(
                      detail,
                      style: typography.caption1.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                ],
              ),
            ),
            if (onDismiss case final dismiss?)
              Tappable(
                tooltip: dismissLabel,
                onTap: dismiss,
                child: Padding(
                  padding: EdgeInsets.all(Spacing.d2),
                  child: Icon(
                    LucideIcons.x,
                    size: Spacing.d14,
                    color: palette.mutedText,
                  ),
                ),
              ),
          ],
        ),
        if (transfer.status.isActive && !transfer.isText) ...[
          Spacing.v8,
          TransferProgressBar(progress: transfer.progress, color: barColor),
        ],
        if (actions.isNotEmpty) ...[
          Spacing.v8,
          Wrap(
            spacing: Spacing.d8,
            runSpacing: Spacing.d8,
            children: [
              for (final action in actions)
                Button(
                  mainAxisSize: .min,
                  variant: switch (action.primary) {
                    true => ButtonVariant.primary,
                    false => ButtonVariant.ghost,
                  },
                  label: action.label,
                  icon: Icon(action.icon, size: Spacing.d14),
                  onPressed: action.onPressed,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
