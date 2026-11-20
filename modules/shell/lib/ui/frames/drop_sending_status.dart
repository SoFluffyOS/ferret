import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class DropSendingStatus extends StatelessWidget {
  const DropSendingStatus({super.key, required this.phase});

  final DropPhase phase;

  @override
  Widget build(BuildContext context) {
    final target = context.select<OsDropViewModel, FilesDropTarget?>(
      (drop) => drop.sendTarget,
    );
    final fileCount = context.select<OsDropViewModel, int>(
      (drop) => drop.fileCount,
    );
    final folderCount = context.select<OsDropViewModel, int>(
      (drop) => drop.folderCount,
    );
    final kind = context.select<OsDropViewModel, DropKind>(
      (drop) => drop.kind,
    );
    final devices = context.select<EngineHost, List<DeviceStatus>>(
      (host) => host.devices,
    );
    final viewModel = context.read<OsDropViewModel>();
    final l10n = context.shellL10n;
    final typography = context.fluffyTheme.typography;
    final palette = context.palette;
    final (name, icon) = switch (target) {
      DeviceDropTarget(:final deviceId, :final name) => (
        name,
        _iconOf(devices, deviceId),
      ),
      _ => (l10n.dropAllDevicesName, LucideIcons.monitorSmartphone),
    };
    final cardName = switch (target) {
      AllDevicesDropTarget() => l10n.dropAllDevices,
      _ => name,
    };
    final title = switch (phase) {
      DropSent() => l10n.dropSentTo(name),
      DropFailed() => l10n.dropFailedTo(name),
      _ => l10n.dropSendingTo(name),
    };

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Text(title, style: typography.title3.copyWith(color: palette.text)),
        Spacing.v16,
        DropProgressCard(
          icon: icon,
          name: cardName,
          fileCount: fileCount,
          folderCount: folderCount,
          kind: kind,
          phase: phase,
        ),
        if (phase is DropFailed) ...[
          Spacing.v12,
          Row(
            mainAxisAlignment: .end,
            children: [
              GhostButton(
                mainAxisSize: .min,
                label: l10n.dropClose,
                onPressed: viewModel.cancel,
              ),
              Spacing.h8,
              Button(
                mainAxisSize: .min,
                variant: .primary,
                label: l10n.dropTryAgain,
                onPressed: () => unawaited(viewModel.retry()),
              ),
            ],
          ),
        ],
      ],
    );
  }

  IconData _iconOf(List<DeviceStatus> devices, String deviceId) {
    for (final status in devices) {
      if (status.device.id == deviceId) {
        return deviceIconFor(status.device.formFactor, status.device.platform);
      }
    }

    return LucideIcons.monitorSmartphone;
  }
}
