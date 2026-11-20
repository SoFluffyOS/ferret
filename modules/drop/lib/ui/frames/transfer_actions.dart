import 'dart:async';

import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:drop/ui/widgets/widgets.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Where to make room after files didn't fit: Open Settings on Android,
/// Show in Finder (or folder) on a computer.
String makeRoomLabel(DropLocalizations l10n) => switch (defaultTargetPlatform) {
  .android => l10n.actionStorageSettings,
  _ => TransferTexts(l10n).revealLabel(),
};

/// The buttons each transfer offers, given where it stands.
List<TransferAction> transferActions(
  DropViewModel viewModel,
  Transfer transfer,
  DropLocalizations l10n, {
  void Function(Transfer transfer)? onEnterPin,
}) {
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
      if (transfer.files.length == 1 || transfer.isFolder)
        TransferAction(
          label: l10n.actionOpen,
          icon: LucideIcons.externalLink,
          primary: true,
          onPressed: () => viewModel.open(transfer),
        ),
      TransferAction(
        label: TransferTexts(l10n).revealLabel(),
        icon: LucideIcons.folderOpen,
        onPressed: () => viewModel.reveal(transfer),
      ),
    ],
    (TransferStatus.failed, _, _)
        when onEnterPin != null && viewModel.needsPin(transfer) =>
      [
        TransferAction(
          label: l10n.actionEnterPin,
          icon: LucideIcons.keyRound,
          primary: true,
          onPressed: () => onEnterPin(transfer),
        ),
      ],
    (TransferStatus.failed, _, _) when viewModel.canMakeRoom(transfer) => [
      TransferAction(
        label: makeRoomLabel(l10n),
        icon: switch (defaultTargetPlatform) {
          .android => LucideIcons.hardDrive,
          _ => LucideIcons.folderOpen,
        },
        onPressed: () => unawaited(viewModel.makeRoom()),
      ),
    ],
    (TransferStatus.failed, _, _) when viewModel.canSendLoose(transfer) => [
      TransferAction(
        label: l10n.actionSendLoose,
        icon: LucideIcons.files,
        primary: true,
        onPressed: () => unawaited(viewModel.sendLoose(transfer)),
      ),
      if (viewModel.canRetry(transfer))
        TransferAction(
          label: l10n.actionRetry,
          icon: LucideIcons.rotateCw,
          onPressed: () => viewModel.retry(transfer),
        ),
    ],
    (TransferStatus.failed, _, _) when transfer.isPaused => [
      TransferAction(
        label: l10n.actionCancel,
        icon: LucideIcons.x,
        onPressed: () => viewModel.cancel(transfer),
      ),
      if (viewModel.canRetry(transfer))
        TransferAction(
          label: l10n.actionTryNow,
          icon: LucideIcons.rotateCw,
          onPressed: () => viewModel.retry(transfer),
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
