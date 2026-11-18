import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// A device's Screen section while its stage is in a window of its own:
/// where things stand, the way back to that window, and Stop.
class ScreenStatusFrame extends StatelessWidget {
  const ScreenStatusFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  final String deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final startedAt = context.select<ViewerViewModel, DateTime?>((viewModel) {
      final session = viewModel.sessionFor(deviceId);
      if (session == null || !session.isLive) {
        return null;
      }

      return session.startedAt;
    });
    final way = context.select<ViewerViewModel, MirrorWay?>(
      (viewModel) => viewModel.sessionFor(deviceId)?.way,
    );
    final stageWindow = context.read<StageWindowViewModel>();
    final l10n = context.mirroringL10n;

    return MirrorMessage(
      icon: LucideIcons.screenShare,
      tone: switch (startedAt) {
        null => .muted,
        _ => .accent,
      },
      title: switch (startedAt) {
        null => l10n.inWindowTitle(deviceName),
        _ => l10n.viewingTitle(deviceName),
      },
      body: switch ((startedAt, way)) {
        (final startedAt?, final way?) => l10n.viewingDetail(
          l10n.time(startedAt),
          l10n.wayName(way),
        ),
        _ => null,
      },
      actions: [
        MessageAction(
          label: l10n.bringToFront,
          primary: true,
          onPressed: () => unawaited(stageWindow.bringToFront()),
        ),
        MessageAction(
          label: l10n.stop,
          onPressed: () => unawaited(stageWindow.close()),
        ),
      ],
    );
  }
}
