import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class DropTileGrid extends StatelessWidget {
  const DropTileGrid({
    super.key,
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
        label: DropTileGrid.label(
          context,
          target,
          hovered: hovered,
          held: held,
        ),
        highlighted: hovered == target && target.acceptsDrop,
        dimmed: !status.isConnected,
        onTap: DropTileGrid.pickWhenHeld(viewModel, target, held: held),
      ),
    );
  }

  /// What a tile says under the device: offline, pick, or drop here.
  static String label(
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

  /// Picking a tile only does something while the files are held.
  static VoidCallback? pickWhenHeld(
    OsDropViewModel viewModel,
    FilesDropTarget target, {
    required bool held,
  }) {
    if (!held || !target.acceptsDrop) {
      return null;
    }

    return () => unawaited(viewModel.pick(target));
  }
}
