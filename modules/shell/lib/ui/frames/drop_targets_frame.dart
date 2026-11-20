import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/drop_choosing_tiles.dart';
import 'package:shell/ui/frames/drop_corner_card.dart';
import 'package:shell/ui/frames/drop_sending_status.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// While files are dragged in, a small view (a phone, the popover) becomes
/// one big tile per device (offline ones faded) plus "All my devices";
/// after the drop, the chosen one shows how sending goes. A window keeps
/// its page: its device list and pane are the targets, and sending shows
/// in a card in the corner. Nothing while idle.
class DropTargetsFrame extends StatelessWidget {
  const DropTargetsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.select<OsDropViewModel, DropPhase>(
      (drop) => drop.phase,
    );
    final fromApp = context.select<OsDropViewModel, bool>(
      (drop) => drop.fromApp,
    );
    final isWindow = WindowLayout.splits(context);
    if (phase is DropIdle) {
      return const SizedBox.shrink();
    }

    if (phase case DropChoosing(held: false) when isWindow || fromApp) {
      return const SizedBox.shrink();
    }

    if (isWindow && phase is! DropChoosing) {
      return DropCornerCard(phase: phase);
    }

    final palette = context.palette;

    return ColoredBox(
      color: palette.background,
      child: Padding(
        padding: EdgeInsets.all(Spacing.d16),
        child: switch (phase) {
          DropChoosing(:final held) => DropChoosingTiles(held: held),
          _ => DropSendingStatus(phase: phase),
        },
      ),
    );
  }
}
