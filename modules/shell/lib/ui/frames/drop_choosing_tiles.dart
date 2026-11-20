import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/drop_nobody_hint.dart';
import 'package:shell/ui/frames/drop_tile_grid.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class DropChoosingTiles extends StatelessWidget {
  const DropChoosingTiles({super.key, required this.held});

  /// Up to this many devices, offline ones keep a faded tile.
  static const tilesBeforeFolding = 4;

  final bool held;

  @override
  Widget build(BuildContext context) {
    final devices = context.select<EngineHost, List<DeviceStatus>>(
      (host) => host.devices,
    );
    final fileCount = context.select<OsDropViewModel, int>(
      (drop) => drop.fileCount,
    );
    final kind = context.select<OsDropViewModel, DropKind>(
      (drop) => drop.kind,
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
    // With many devices, offline tiles would push the ones that can take
    // the files off screen: they fold into one line.
    final foldsOffline =
        devices.length > DropChoosingTiles.tilesBeforeFolding &&
        connectedCount > 0;
    final tiles = switch (foldsOffline) {
      true => [
        for (final status in devices)
          if (status.isConnected || status.isReconnecting) status,
      ],
      false => devices,
    };
    final folded = devices.length - tiles.length;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                switch (kind) {
                  .files => l10n.dropTitle(fileCount),
                  .text => l10n.dropTitleText,
                  .link => l10n.dropTitleLink,
                },
                style: typography.title3.copyWith(color: palette.text),
              ),
            ),
            if (held)
              GhostButton(
                mainAxisSize: .min,
                label: l10n.dropCancel,
                onPressed: viewModel.cancel,
              ),
          ],
        ),
        Spacing.v16,
        Expanded(
          child: switch (connectedCount) {
            0 when devices.isEmpty => const DropNobodyHint(),
            _ => DropTileGrid(devices: tiles, hovered: hovered, held: held),
          },
        ),
        if (folded > 0) ...[
          Spacing.v8,
          Text(
            l10n.dropOfflineCount(folded),
            textAlign: .center,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        ],
        if (connectedCount == 0 && devices.isNotEmpty) ...[
          Spacing.v12,
          const DropNobodyHint(),
        ],
        if (connectedCount >= 2) ...[
          Spacing.v8,
          DropTargetRegion(
            target: all,
            child: DropTargetTile(
              icon: LucideIcons.monitorSmartphone,
              name: l10n.dropAllDevices,
              label: DropTileGrid.label(
                context,
                all,
                hovered: hovered,
                held: held,
              ),
              highlighted: hovered == all,
              compact: true,
              onTap: DropTileGrid.pickWhenHeld(viewModel, all, held: held),
            ),
          ),
        ],
      ],
    );
  }
}
