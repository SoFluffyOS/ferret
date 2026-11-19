import 'dart:async';

import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:drop/ui/frames/transfer_actions.dart';
import 'package:drop/ui/widgets/widgets.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Drop's home card: active and recent transfers, or a hint to send some,
/// and, folded under "Receive from other apps", the switches that let
/// LocalSend devices and Quick Share on phones send here for a while.
class DropHomeFrame extends StatelessWidget {
  const DropHomeFrame({
    super.key,
    required this.onSendFiles,
    this.needsYouOnly = false,
  });

  /// Shows only what waits for the person here: a PIN to enter, and who
  /// may send here right now. Home uses it; offers to answer and
  /// everything else are lines from Drop's activity.
  final bool needsYouOnly;

  /// Picks files and a device, then sends.
  final VoidCallback onSendFiles;

  static const _shown = 5;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DropViewModel>();
    final transfers = context.select<DropViewModel, List<Transfer>>(
      (model) => switch (needsYouOnly) {
        true => model.needingPin,
        false => model.transfers,
      },
    );
    final canSend = context.select<DropViewModel, bool>(
      (model) => model.canSend,
    );
    final localSend = context.select<DropViewModel, bool>(
      (model) => model.localSendEnabled,
    );
    final receiving = context.select<DropViewModel, LocalSendReceiveState>(
      (model) => model.receiveState,
    );
    final secondsLeft = context.select<DropViewModel, int?>(
      (model) => model.receiveSecondsLeft,
    );
    final quickShare = context.select<DropViewModel, bool>(
      (model) => model.quickShareEnabled,
    );
    final visibility = context.select<DropViewModel, QuickShareReceiveState>(
      (model) => model.quickShareState,
    );
    final visibleSecondsLeft = context.select<DropViewModel, int?>(
      (model) => model.quickShareSecondsLeft,
    );
    final hasFinished = context.select<DropViewModel, bool>(
      (model) => model.hasFinished,
    );
    final guestOnce = context.select<DropViewModel, bool>(
      (model) => model.isGuestOnce,
    );
    final l10n = context.dropL10n;
    final texts = context.transferTexts;

    return FeatureCard(
      icon: LucideIcons.send,
      title: l10n.title,
      subtitle: switch (transfers.isEmpty && !needsYouOnly) {
        true => _emptyLine(l10n),
        false => null,
      },
      trailing: switch (hasFinished && !needsYouOnly) {
        true => Button(
          mainAxisSize: .min,
          variant: .ghost,
          label: l10n.clearFinished,
          onPressed: viewModel.clearFinished,
        ),
        false => null,
      },
      children: [
        for (final (index, transfer) in transfers.take(_shown).indexed) ...[
          if (index > 0) Spacing.v16,
          TransferTile(
            key: ValueKey(transfer.id),
            transfer: transfer,
            title: texts.title(transfer),
            status: texts.status(transfer),
            speed: texts.speed(
              transfer,
              isWeak: viewModel.isWeak(transfer),
            ),
            details: texts.offerDetails(transfer),
            actions: transferActions(
              viewModel,
              transfer,
              l10n,
              onEnterPin: (failed) =>
                  unawaited(_enterPin(context, viewModel, failed)),
            ),
            dismissLabel: l10n.actionDismiss,
            onDismiss: switch (transfer.status.isActive) {
              true => null,
              false => () => viewModel.dismiss(transfer),
            },
          ),
        ],
        if (localSend || quickShare) ...[
          if (transfers.isNotEmpty) Spacing.v16,
          DisclosureRow(
            title: l10n.otherApps,
            keepOpen: _isBusy(receiving) || _isVisible(visibility),
            children: [
              if (guestOnce)
                Text(
                  l10n.guestWaiting,
                  style: context.fluffyTheme.typography.caption1.copyWith(
                    color: context.palette.mutedText,
                  ),
                ),
              if (localSend)
                ReceiveRow(
                  title: l10n.receiveTitle,
                  status: _receiveStatus(receiving, secondsLeft, l10n, texts),
                  hasProblem: receiving.problem != null,
                  actionLabel: _receiveAction(receiving, l10n),
                  onAction: switch ((receiving.isStarting, receiving.isOn)) {
                    (true, _) => null,
                    (false, true) => viewModel.stopReceiving,
                    (false, false) => viewModel.receiveFromLocalSend,
                  },
                ),
              if (quickShare)
                ReceiveRow(
                  icon: LucideIcons.smartphone,
                  title: l10n.quickShareTitle,
                  status: _visibilityStatus(
                    visibility,
                    visibleSecondsLeft,
                    l10n,
                    texts,
                  ),
                  hasProblem: visibility.problem != null,
                  actionLabel: _visibilityAction(visibility, l10n),
                  onAction: switch ((visibility.isStarting, visibility.isOn)) {
                    (true, _) => null,
                    (false, true) => viewModel.stopQuickShare,
                    (false, false) => viewModel.receiveFromQuickShare,
                  },
                ),
            ],
          ),
        ],
      ],
      actions: [
        if (canSend && !needsYouOnly)
          Button(
            mainAxisSize: .min,
            variant: .ghost,
            label: l10n.sendFiles,
            icon: Icon(LucideIcons.upload, size: Spacing.d14),
            onPressed: onSendFiles,
          ),
      ],
    );
  }

  String _emptyLine(DropLocalizations l10n) => switch (defaultTargetPlatform) {
    .android || .iOS => l10n.cardEmptyPhone,
    _ => l10n.cardEmpty,
  };

  bool _isBusy(LocalSendReceiveState state) =>
      state.isStarting || state.isOn || state.problem != null;

  bool _isVisible(QuickShareReceiveState state) =>
      state.isStarting || state.isOn || state.problem != null;

  String _receiveStatus(
    LocalSendReceiveState state,
    int? secondsLeft,
    DropLocalizations l10n,
    TransferTexts texts,
  ) {
    if (state.isStarting) {
      return l10n.receiveStarting;
    }

    if (state.problem case final problem?) {
      return switch (problem) {
        LocalSendProblem.cannotListen => l10n.receiveCannotListen,
        LocalSendProblem.noIdentity => l10n.receiveNoIdentity,
      };
    }

    if (!state.isOn) {
      return l10n.receiveOff;
    }

    if (secondsLeft == null) {
      return l10n.receiveAlwaysOn(state.alias);
    }

    return l10n.receiveTimed(
      state.alias,
      texts.countdown(Duration(seconds: secondsLeft)),
    );
  }

  String _receiveAction(LocalSendReceiveState state, DropLocalizations l10n) {
    if (state.isOn) {
      return l10n.receiveStop;
    }

    if (state.problem != null) {
      return l10n.receiveTryAgain;
    }

    return l10n.receiveTurnOn;
  }

  String _visibilityStatus(
    QuickShareReceiveState state,
    int? secondsLeft,
    DropLocalizations l10n,
    TransferTexts texts,
  ) {
    if (state.isStarting) {
      return l10n.receiveStarting;
    }

    if (state.problem case final problem?) {
      return switch (problem) {
        QuickShareProblem.cannotListen => l10n.receiveCannotListen,
        QuickShareProblem.cannotAdvertise => l10n.quickShareCannotAdvertise,
      };
    }

    if (!state.isOn) {
      return l10n.quickShareOff;
    }

    if (secondsLeft == null || secondsLeft <= 0) {
      return l10n.quickShareFinishing;
    }

    return l10n.receiveTimed(
      state.name,
      texts.countdown(Duration(seconds: secondsLeft)),
    );
  }

  String _visibilityAction(
    QuickShareReceiveState state,
    DropLocalizations l10n,
  ) {
    if (state.isOn) {
      return l10n.receiveStop;
    }

    if (state.problem != null) {
      return l10n.receiveTryAgain;
    }

    return l10n.quickShareTurnOn;
  }

  Future<void> _enterPin(
    BuildContext context,
    DropViewModel viewModel,
    Transfer transfer,
  ) async {
    final l10n = context.dropL10n;
    final pin = await InputTextDialog.show(
      context,
      title: l10n.pinTitle(transfer.deviceName),
      labelText: l10n.pinLabel,
      cancelText: l10n.actionCancel,
      confirmText: l10n.pinSend,
    );
    if (pin == null || pin.trim().isEmpty) {
      return;
    }

    await viewModel.retryWithPin(transfer, pin);
  }
}
