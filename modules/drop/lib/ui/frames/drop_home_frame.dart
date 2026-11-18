import 'dart:async';

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

/// Drop's home card: active and recent transfers, or a hint to send some,
/// and the switch that lets LocalSend devices send here for a while.
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
    final hasFinished = context.select<DropViewModel, bool>(
      (model) => model.hasFinished,
    );
    final l10n = context.dropL10n;
    final texts = context.transferTexts;

    return FeatureCard(
      icon: LucideIcons.send,
      title: l10n.title,
      subtitle: switch (transfers.isEmpty) {
        true => l10n.cardEmpty,
        false => null,
      },
      trailing: switch (hasFinished) {
        true => Button(
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
            speed: texts.speed(transfer),
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
        if (localSend) ...[
          if (transfers.isNotEmpty) Spacing.v16,
          LocalSendReceiveRow(
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
        ],
      ],
      actions: [
        if (canSend)
          Button(
            variant: .secondary,
            label: l10n.sendFiles,
            icon: Icon(LucideIcons.upload, size: Spacing.d14),
            onPressed: onSendFiles,
          ),
      ],
    );
  }

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
