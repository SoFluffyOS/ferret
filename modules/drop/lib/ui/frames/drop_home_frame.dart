import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:drop/ui/frames/transfer_actions.dart';
import 'package:drop/ui/widgets/widgets.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Drop's home card: active and recent transfers, or a hint to send some.
class DropHomeFrame extends StatelessWidget {
  const DropHomeFrame({super.key, required this.onSendFiles});

  /// Picks files and a device, then sends.
  final VoidCallback onSendFiles;

  static const _shown = 5;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DropViewModel>();
    final transfers = context.select<DropViewModel, List<Transfer>>(
      (model) => model.transfers,
    );
    final canSend = context.select<DropViewModel, bool>(
      (model) => model.targets.isNotEmpty,
    );
    final hasFinished = context.select<DropViewModel, bool>(
      (model) => model.hasFinished,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.dropL10n;
    final texts = context.transferTexts;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.send, size: Spacing.d16, color: palette.text),
              Spacing.h8,
              Expanded(
                child: Text(
                  l10n.title,
                  style: typography.base1.copyWith(color: palette.text),
                ),
              ),
              if (hasFinished)
                Button(
                  variant: .ghost,
                  label: l10n.clearFinished,
                  onPressed: viewModel.clearFinished,
                ),
            ],
          ),
          Spacing.v8,
          if (transfers.isEmpty)
            Text(
              l10n.cardEmpty,
              style: typography.body2.copyWith(color: palette.mutedText),
            ),
          for (final (index, transfer) in transfers.take(_shown).indexed) ...[
            if (index > 0) Spacing.v16,
            TransferTile(
              key: ValueKey(transfer.id),
              transfer: transfer,
              title: texts.title(transfer),
              status: texts.status(transfer),
              speed: texts.speed(transfer),
              actions: transferActions(viewModel, transfer, l10n),
              dismissLabel: l10n.actionDismiss,
              onDismiss: switch (transfer.status.isActive) {
                true => null,
                false => () => viewModel.dismiss(transfer),
              },
            ),
          ],
          if (canSend) ...[
            Spacing.v12,
            Button(
              variant: .secondary,
              label: l10n.sendFiles,
              icon: Icon(LucideIcons.upload, size: Spacing.d14),
              onPressed: onSendFiles,
            ),
          ],
        ],
      ),
    );
  }
}
