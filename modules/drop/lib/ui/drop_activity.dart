import 'dart:async';

import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Drop's lines in Activity: each transfer, pinned with its progress while
/// bytes move, then where it went. Offers that wait for an answer stay on
/// the card, where Accept and Decline are.
List<ActivityItem> dropActivity(
  DropLocalizations l10n,
  DropViewModel viewModel,
) {
  final texts = TransferTexts(l10n);

  return [
    for (final transfer in viewModel.transfers)
      if (!transfer.needsAnswer && !viewModel.needsPin(transfer))
        ActivityItem(
          id: 'drop.${transfer.id}',
          icon: _icon(transfer),
          tone: _tone(transfer),
          title: _title(l10n, texts, transfer),
          detail: _detail(l10n, texts, viewModel, transfer),
          at: transfer.startedAt,
          pinned: transfer.status.isActive,
          progress: switch (transfer.status) {
            .transferring || .verifying => transfer.progress,
            _ => null,
          },
          actions: _actions(l10n, viewModel, transfer),
        ),
  ];
}

IconData _icon(Transfer transfer) => switch (transfer.status) {
  .failed => LucideIcons.triangleAlert,
  _ => switch (transfer.isOutgoing) {
    true => LucideIcons.arrowUp,
    false => LucideIcons.arrowDown,
  },
};

FeatureTone _tone(Transfer transfer) => switch (transfer.status) {
  .failed => .danger,
  .cancelled => .muted,
  _ => .normal,
};

/// "IMG_2041.jpg from Pixel 9", "3 files to Pixel 9".
String _title(
  DropLocalizations l10n,
  TransferTexts texts,
  Transfer transfer,
) {
  final what = switch (transfer.isText) {
    true => l10n.activityText,
    false => texts.title(transfer),
  };

  return switch (transfer.isOutgoing) {
    true => l10n.activityTo(what, transfer.deviceName),
    false => l10n.activityFrom(what, transfer.deviceName),
  };
}

String _detail(
  DropLocalizations l10n,
  TransferTexts texts,
  DropViewModel viewModel,
  Transfer transfer,
) {
  if (transfer.status != .done) {
    return texts.status(transfer);
  }

  if (transfer.isOutgoing) {
    return l10n.activitySent;
  }

  if (transfer.isText) {
    return texts.preview(transfer.text ?? '');
  }

  final folder = viewModel.receiveFolderLabel;
  if (folder.isEmpty) {
    return l10n.activitySaved;
  }

  return l10n.activitySavedTo(folder);
}

List<ActivityAction> _actions(
  DropLocalizations l10n,
  DropViewModel viewModel,
  Transfer transfer,
) {
  if (transfer.status.isActive) {
    return [
      ActivityAction(
        label: l10n.actionCancel,
        onPressed: () => unawaited(viewModel.cancel(transfer)),
      ),
    ];
  }

  return switch ((transfer.status, transfer.isOutgoing, transfer.isText)) {
    (.done, false, true) => [
      ActivityAction(
        label: l10n.actionCopy,
        onPressed: () => unawaited(viewModel.copy(transfer)),
      ),
    ],
    (.done, false, false) when transfer.files.length == 1 => [
      ActivityAction(
        label: l10n.actionOpen,
        onPressed: () => unawaited(viewModel.open(transfer)),
      ),
    ],
    (.done, false, false) => [
      ActivityAction(
        label: l10n.actionReveal,
        onPressed: () => unawaited(viewModel.reveal(transfer)),
      ),
    ],
    (.failed, _, _) when viewModel.canRetry(transfer) => [
      ActivityAction(
        label: l10n.actionRetry,
        onPressed: () => unawaited(viewModel.retry(transfer)),
      ),
    ],
    _ => const [],
  };
}
