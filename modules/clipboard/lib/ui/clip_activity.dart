import 'dart:async';

import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/models/models.dart';
import 'package:clipboard/ui/widgets/widgets.dart';
import 'package:clipboard/view_models/clipboard_view_model.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _previewLength = 60;

/// Clipboard's lines in Activity: each clip that came or went, and why the
/// last Send clipboard didn't go through.
List<ActivityItem> clipActivity(
  ClipboardLocalizations l10n,
  ClipboardViewModel viewModel,
) => [
  ?_failedSend(l10n, viewModel),
  for (final entry in viewModel.history) _clip(l10n, viewModel, entry),
];

ActivityItem? _failedSend(
  ClipboardLocalizations l10n,
  ClipboardViewModel viewModel,
) {
  final result = viewModel.lastResult;
  if (result == null || result == .sent) {
    return null;
  }

  return ActivityItem(
    id: 'clipboard.result',
    icon: LucideIcons.clipboardX,
    title: l10n.activityNotSent,
    detail: l10n.resultOf(result),
    at: viewModel.lastResultAt,
    tone: .warning,
  );
}

ActivityItem _clip(
  ClipboardLocalizations l10n,
  ClipboardViewModel viewModel,
  ClipEntry entry,
) {
  final canCopy = entry.direction == .received && entry.hasContent;

  return ActivityItem(
    id: 'clipboard.${entry.id}',
    icon: LucideIcons.clipboard,
    title: _title(l10n, entry),
    detail: _detail(l10n, entry),
    deviceId: switch (entry.deviceIds) {
      [final only] => only,
      _ => null,
    },
    at: entry.at,
    tone: switch (entry.skip) {
      .none => .normal,
      _ => .muted,
    },
    actions: [
      if (canCopy)
        ActivityAction(
          label: l10n.copy,
          onPressed: () => unawaited(viewModel.copy(entry)),
        ),
    ],
  );
}

String _title(ClipboardLocalizations l10n, ClipEntry entry) {
  final devices = entry.deviceNames.join(', ');
  return switch (entry.skip) {
    .sensitive => l10n.skippedSensitive,
    .imagesOff => l10n.skippedImagesOff,
    .tooLarge => l10n.skippedTooLarge,
    .noDevices => l10n.sentNowhere,
    .writeFailed => l10n.writeFailed(devices),
    .none => switch (entry.direction) {
      .sent => l10n.sentTo(devices),
      .received => l10n.activityCopiedOn(devices),
    },
  };
}

/// A private clip never shows its content here, not even blurred.
String _detail(ClipboardLocalizations l10n, ClipEntry entry) {
  if (entry.redacted) {
    return l10n.privateCleared;
  }

  if (!entry.hasContent || entry.isSensitive) {
    return l10n.privateHidden;
  }

  if (entry.isImage) {
    return l10n.imageLabel;
  }

  final firstLine = entry.item.text.trim().split('\n').first;
  if (firstLine.length <= _previewLength) {
    return l10n.activityQuote(firstLine);
  }

  return l10n.activityQuote('${firstLine.substring(0, _previewLength)}…');
}
