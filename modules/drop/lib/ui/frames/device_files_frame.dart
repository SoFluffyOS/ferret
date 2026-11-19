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

/// The Files section of one device: a place to drop or choose files, and
/// every transfer with that device under it.
class DeviceFilesFrame extends StatelessWidget {
  const DeviceFilesFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.isConnected,
  });

  final String deviceId;
  final String deviceName;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DropViewModel>();
    final transfers = context.select<DropViewModel, List<Transfer>>(
      (model) => [
        for (final transfer in model.transfers)
          if (transfer.deviceId == deviceId) transfer,
      ],
    );
    // Progress changes inside a transfer, not in the list.
    context.select<DropViewModel, int>(
      (model) => Object.hashAll([
        for (final transfer in model.transfers)
          if (transfer.deviceId == deviceId)
            (transfer.status, transfer.progress),
      ]),
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.dropL10n;
    final texts = context.transferTexts;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SurfaceCard(
          padding: EdgeInsets.all(Spacing.d24),
          child: Column(
            children: [
              Icon(
                LucideIcons.upload,
                size: Spacing.d32,
                color: palette.mutedText,
              ),
              Spacing.v12,
              Text(
                switch (isConnected) {
                  true => l10n.filesDropHere(deviceName),
                  false => l10n.filesOffline(deviceName),
                },
                textAlign: .center,
                style: typography.base2.copyWith(color: palette.mutedText),
              ),
              Spacing.v16,
              Button(
                variant: .primary,
                mainAxisSize: .min,
                enable: isConnected,
                label: l10n.filesChoose,
                onPressed: () => unawaited(viewModel.pickAndSend(deviceId)),
              ),
            ],
          ),
        ),
        SectionTitle(l10n.filesRecent),
        if (transfers.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
            child: Text(
              l10n.filesNone(deviceName),
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ),
        if (transfers.isNotEmpty)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                for (final (index, transfer) in transfers.indexed) ...[
                  if (index > 0) Spacing.v16,
                  TransferTile(
                    key: ValueKey(transfer.id),
                    transfer: transfer,
                    title: texts.title(transfer),
                    status: texts.status(transfer),
                    speed: texts.speed(transfer),
                    details: texts.offerDetails(transfer),
                    actions: transferActions(viewModel, transfer, l10n),
                    dismissLabel: l10n.actionDismiss,
                    onDismiss: switch (transfer.status.isActive) {
                      true => null,
                      false => () => viewModel.dismiss(transfer),
                    },
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
