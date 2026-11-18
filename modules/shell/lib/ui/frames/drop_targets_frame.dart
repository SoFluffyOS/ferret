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

/// While files are dragged in, the whole window becomes one big tile per
/// device (offline ones faded) plus "All my devices"; after the drop, the
/// chosen one shows how sending goes. Nothing while idle.
class DropTargetsFrame extends StatelessWidget {
  const DropTargetsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.select<OsDropViewModel, DropPhase>(
      (drop) => drop.phase,
    );
    if (phase is DropIdle) {
      return const SizedBox.shrink();
    }

    final palette = context.palette;

    return ColoredBox(
      color: palette.background,
      child: Padding(
        padding: EdgeInsets.all(Spacing.d16),
        child: switch (phase) {
          DropChoosing(:final held) => _Choosing(held: held),
          _ => _Sending(phase: phase),
        },
      ),
    );
  }
}

class _Choosing extends StatelessWidget {
  const _Choosing({required this.held});

  final bool held;

  @override
  Widget build(BuildContext context) {
    final devices = context.select<EngineHost, List<DeviceStatus>>(
      (host) => host.devices,
    );
    final fileCount = context.select<OsDropViewModel, int>(
      (drop) => drop.fileCount,
    );
    final hovered = context.select<OsDropViewModel, FilesDropTarget?>(
      (drop) => drop.hovered,
    );
    final viewModel = context.read<OsDropViewModel>();
    final l10n = context.shellL10n;
    final typography = context.fluffyTheme.typography;
    final palette = context.palette;
    final connectedCount = devices.where((status) => status.isConnected).length;
    const all = AllDevicesDropTarget();

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.dropTitle(fileCount),
                style: typography.title3.copyWith(color: palette.text),
              ),
            ),
            if (held)
              Button(
                mainAxisSize: .min,
                variant: .ghost,
                label: l10n.dropCancel,
                onPressed: viewModel.cancel,
              ),
          ],
        ),
        Spacing.v16,
        Expanded(
          child: switch (connectedCount) {
            0 when devices.isEmpty => const _Nobody(),
            _ => _TileGrid(devices: devices, hovered: hovered, held: held),
          },
        ),
        if (connectedCount == 0 && devices.isNotEmpty) ...[
          Spacing.v12,
          const _Nobody(),
        ],
        if (connectedCount >= 2) ...[
          Spacing.v8,
          DropTargetRegion(
            target: all,
            child: DropTargetTile(
              icon: LucideIcons.monitorSmartphone,
              name: l10n.dropAllDevices,
              label: _label(context, all, hovered: hovered, held: held),
              highlighted: hovered == all,
              compact: true,
              onTap: _pickWhenHeld(viewModel, all, held: held),
            ),
          ),
        ],
      ],
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({
    required this.devices,
    required this.hovered,
    required this.held,
  });

  final List<DeviceStatus> devices;
  final FilesDropTarget? hovered;
  final bool held;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<OsDropViewModel>();
    final columns = switch (devices.length) {
      <= 2 => 1,
      _ => 2,
    };
    final rows = (devices.length / columns).ceil();
    final gap = Spacing.d8;
    final minimumHeight = Spacing.d96 + Spacing.d24;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitHeight = (constraints.maxHeight - gap * (rows - 1)) / rows;
        final scrolls = fitHeight < minimumHeight;
        final rowHeight = switch (scrolls) {
          true => minimumHeight,
          false => fitHeight,
        };
        final grid = Column(
          children: [
            for (var row = 0; row < rows; row++) ...[
              if (row > 0) SizedBox(height: gap),
              SizedBox(
                height: rowHeight,
                child: Row(
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) SizedBox(width: gap),
                      Expanded(
                        child: switch (row * columns + column) {
                          final index when index < devices.length => _tile(
                            context,
                            viewModel,
                            devices[index],
                          ),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
        if (!scrolls) {
          return grid;
        }

        return SingleChildScrollView(child: grid);
      },
    );
  }

  Widget _tile(
    BuildContext context,
    OsDropViewModel viewModel,
    DeviceStatus status,
  ) {
    final device = status.device;
    final target = DeviceDropTarget(
      deviceId: device.id,
      name: device.name,
      isConnected: status.isConnected,
    );

    return DropTargetRegion(
      target: target,
      child: DropTargetTile(
        icon: deviceIconFor(device.formFactor, device.platform),
        name: device.name,
        label: _label(context, target, hovered: hovered, held: held),
        highlighted: hovered == target && target.acceptsDrop,
        dimmed: !status.isConnected,
        onTap: _pickWhenHeld(viewModel, target, held: held),
      ),
    );
  }
}

class _Nobody extends StatelessWidget {
  const _Nobody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final typography = context.fluffyTheme.typography;
    final palette = context.palette;

    return Column(
      mainAxisSize: .min,
      children: [
        Text(
          l10n.dropNobody,
          style: typography.base1.copyWith(
            color: palette.text,
            fontWeight: .w600,
          ),
          textAlign: .center,
        ),
        Spacing.vertical(Spacing.d2),
        Text(
          l10n.dropNobodyDetail,
          style: typography.caption1.copyWith(color: palette.mutedText),
          textAlign: .center,
        ),
      ],
    );
  }
}

class _Sending extends StatelessWidget {
  const _Sending({required this.phase});

  final DropPhase phase;

  @override
  Widget build(BuildContext context) {
    final target = context.select<OsDropViewModel, FilesDropTarget?>(
      (drop) => drop.sendTarget,
    );
    final fileCount = context.select<OsDropViewModel, int>(
      (drop) => drop.fileCount,
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
      crossAxisAlignment: .stretch,
      children: [
        Text(title, style: typography.title3.copyWith(color: palette.text)),
        Spacing.v16,
        DropProgressCard(
          icon: icon,
          name: cardName,
          fileCount: fileCount,
          phase: phase,
        ),
        if (phase is DropFailed) ...[
          Spacing.v12,
          Row(
            mainAxisAlignment: .end,
            children: [
              Button(
                mainAxisSize: .min,
                variant: .ghost,
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

String _label(
  BuildContext context,
  FilesDropTarget target, {
  required FilesDropTarget? hovered,
  required bool held,
}) {
  final l10n = context.shellL10n;
  if (!target.acceptsDrop) {
    return l10n.dropTileOffline;
  }

  if (held) {
    return l10n.dropTilePick;
  }

  if (hovered == target) {
    return l10n.dropTileDrop;
  }

  return '';
}

VoidCallback? _pickWhenHeld(
  OsDropViewModel viewModel,
  FilesDropTarget target, {
  required bool held,
}) {
  if (!held || !target.acceptsDrop) {
    return null;
  }

  return () => unawaited(viewModel.pick(target));
}
