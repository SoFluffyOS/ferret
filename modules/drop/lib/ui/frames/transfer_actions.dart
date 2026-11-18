import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:drop/ui/widgets/widgets.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The buttons each transfer offers, given where it stands.
List<TransferAction> transferActions(
  DropViewModel viewModel,
  Transfer transfer,
  DropLocalizations l10n,
) {
  if (transfer.needsAnswer) {
    return [
      TransferAction(
        label: l10n.actionAccept,
        icon: LucideIcons.check,
        primary: true,
        onPressed: () => viewModel.accept(transfer),
      ),
      TransferAction(
        label: l10n.actionDecline,
        icon: LucideIcons.ban,
        onPressed: () => viewModel.decline(transfer),
      ),
    ];
  }

  if (transfer.status.isActive) {
    return [
      TransferAction(
        label: l10n.actionCancel,
        icon: LucideIcons.x,
        onPressed: () => viewModel.cancel(transfer),
      ),
    ];
  }

  return switch ((transfer.status, transfer.isOutgoing, transfer.isText)) {
    (TransferStatus.done, false, true) => [
      TransferAction(
        label: l10n.actionCopy,
        icon: LucideIcons.copy,
        primary: true,
        onPressed: () => viewModel.copy(transfer),
      ),
    ],
    (TransferStatus.done, false, false) => [
      if (transfer.files.length == 1)
        TransferAction(
          label: l10n.actionOpen,
          icon: LucideIcons.externalLink,
          primary: true,
          onPressed: () => viewModel.open(transfer),
        ),
      TransferAction(
        label: l10n.actionReveal,
        icon: LucideIcons.folderOpen,
        onPressed: () => viewModel.reveal(transfer),
      ),
    ],
    (TransferStatus.failed, _, _) when viewModel.canRetry(transfer) => [
      TransferAction(
        label: l10n.actionRetry,
        icon: LucideIcons.rotateCw,
        primary: true,
        onPressed: () => viewModel.retry(transfer),
      ),
    ],
    _ => const [],
  };
}
