import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:updates/l10n/l10n.dart';
import 'package:updates/models/models.dart';
import 'package:updates/view_models/view_models.dart';

/// The update as one line: under Needs you while it waits for the person
/// ("Ferret 0.2.0 is ready" with Install and What's new, or why it
/// stopped), and as a line with a bar while it downloads and installs.
/// The ✕ puts it off until the next version.
abstract final class UpdateActivity {
  static const id = 'update';

  /// The line for [viewModel]'s state, or null when there is nothing to
  /// say.
  static ActivityItem? of(
    UpdatesLocalizations l10n,
    UpdatesViewModel viewModel, {
    required VoidCallback onWhatsNew,
    required VoidCallback onDownloadPage,
  }) {
    final release = viewModel.release;
    if (!viewModel.showsLine || release == null) {
      return null;
    }

    final version = release.versionText;
    final current = l10n.youHave(viewModel.currentVersion);
    void later() => unawaited(viewModel.dismiss());
    final whatsNew = ActivityAction(
      label: l10n.whatsNew,
      onPressed: onWhatsNew,
    );
    final downloadPage = ActivityAction(
      label: l10n.downloadPage,
      tooltip: l10n.downloadPageTooltip,
      onPressed: onDownloadPage,
    );

    return switch (viewModel.phase) {
      .downloading || .verifying || .installing || .restarting => ActivityItem(
        id: id,
        icon: LucideIcons.circleArrowUp,
        title: l10n.ready(version),
        detail: progressText(l10n, viewModel),
        pinned: true,
        progress: switch (viewModel.phase) {
          .downloading => viewModel.progress ?? 0,
          .restarting => 1,
          _ => null,
        },
        actions: [
          if (viewModel.phase == .downloading)
            ActivityAction(label: l10n.cancel, onPressed: viewModel.cancel),
        ],
      ),
      .needsPermission => ActivityItem(
        id: id,
        icon: LucideIcons.shieldAlert,
        title: l10n.permissionTitle,
        detail: l10n.permissionBody,
        needsYou: true,
        tone: .warning,
        onDismiss: later,
        actions: [
          ActivityAction(
            label: l10n.openSettings,
            tooltip: l10n.openSettingsTooltip,
            primary: true,
            onPressed: () => unawaited(viewModel.allowInstalls()),
          ),
        ],
      ),
      .handedToSystem => ActivityItem(
        id: id,
        icon: LucideIcons.circleArrowUp,
        title: l10n.ready(version),
        detail: l10n.confirmOnPhone,
        needsYou: true,
        onDismiss: later,
        actions: [
          ActivityAction(
            label: l10n.showPrompt,
            tooltip: l10n.showPromptTooltip,
            onPressed: () => unawaited(viewModel.install()),
          ),
        ],
      ),
      .openedForYou => ActivityItem(
        id: id,
        icon: LucideIcons.packageOpen,
        title: l10n.dragTitle,
        detail: l10n.dragBody,
        needsYou: true,
        onDismiss: later,
      ),
      .failed => ActivityItem(
        id: id,
        icon: LucideIcons.shieldX,
        title: l10n.notInstalled,
        detail: problemText(l10n, viewModel.problem),
        needsYou: true,
        tone: .danger,
        onDismiss: later,
        actions: [
          if (viewModel.problem?.canRetry ?? false)
            ActivityAction(
              label: l10n.tryAgain,
              primary: true,
              onPressed: () => unawaited(viewModel.install()),
            ),
          downloadPage,
        ],
      ),
      _ => ActivityItem(
        id: id,
        icon: LucideIcons.circleArrowUp,
        title: switch (viewModel.kind.installsItself) {
          true => l10n.ready(version),
          false => l10n.readyOut(version),
        },
        detail: switch (viewModel.kind) {
          .packageManager => '$current · ${l10n.packageManager}',
          _ when !viewModel.kind.installsItself =>
            '$current · ${l10n.manualInstall}',
          _ => current,
        },
        needsYou: true,
        onDismiss: later,
        actions: [
          if (viewModel.kind.installsItself)
            ActivityAction(
              label: l10n.install,
              tooltip: l10n.installTooltip(version),
              primary: true,
              onPressed: () => unawaited(viewModel.install()),
            ),
          if (!viewModel.kind.installsItself &&
              viewModel.kind != .packageManager)
            ActivityAction(
              label: l10n.downloadPage,
              tooltip: l10n.downloadPageTooltip,
              primary: true,
              onPressed: onDownloadPage,
            ),
          whatsNew,
        ],
      ),
    };
  }

  /// What the download or install is doing right now.
  static String progressText(
    UpdatesLocalizations l10n,
    UpdatesViewModel viewModel,
  ) => switch (viewModel.phase) {
    .downloading => switch (viewModel.progress) {
      final value? => l10n.downloading((value * 100).round()),
      null => l10n.downloadingNoSize,
    },
    .verifying => l10n.verifying,
    .installing => l10n.installing,
    _ => l10n.restarting,
  };

  /// Why the update stopped, in a sentence.
  static String problemText(
    UpdatesLocalizations l10n,
    UpdateProblem? problem,
  ) => switch (problem) {
    .checkFailed => l10n.checkFailed,
    .noFile => l10n.noFile,
    .downloadFailed => l10n.downloadFailed,
    .checksumMissing => l10n.checksumMissing,
    .checksumMismatch => l10n.checksumMismatch,
    .notSigned => l10n.notSigned,
    .wrongPublisher => l10n.wrongPublisher,
    .notNotarized => l10n.notNotarized,
    .unsignedHere => l10n.unsignedHere,
    .installFailed || null => l10n.installFailed,
  };
}
