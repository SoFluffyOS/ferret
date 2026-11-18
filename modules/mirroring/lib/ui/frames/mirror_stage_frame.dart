import 'dart:async';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/frames/airplay_guide_frame.dart';
import 'package:mirroring/ui/frames/mirror_ended_frame.dart';
import 'package:mirroring/ui/frames/mirror_live_frame.dart';
import 'package:mirroring/ui/frames/mirror_setup_frame.dart';
import 'package:mirroring/ui/frames/mirror_waiting_frame.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// One device's screen from the first question to the ending, in one
/// place: asking, the wait on the phone, a missing step, the picture with
/// its toolbar, and how it ended. Whatever hosts it (a page, a pane, a
/// window of its own) only gives it room and a way to close.
class MirrorStageFrame extends StatelessWidget {
  const MirrorStageFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    this.onClose,
    this.clock,
  });

  final String deviceId;
  final String deviceName;

  /// Closes what hosts the stage: Stop, Cancel and Close all end there.
  /// Null where the host stays, such as a pane.
  final VoidCallback? onClose;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final pending = context.select<ViewerViewModel, PendingShow?>(
      (viewModel) => viewModel.pendingShow,
    );
    final showsCableGuide = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.cableGuideFor == deviceId,
    );
    final showsAirplayGuide = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.airplayGuideFor == deviceId,
    );
    final phase = context.select<ViewerViewModel, ViewPhase?>(
      (viewModel) => viewModel.sessionFor(deviceId)?.phase,
    );
    final end = context.select<ViewerViewModel, ViewEnd?>(
      (viewModel) => viewModel.sessionFor(deviceId)?.end,
    );
    final way = context.select<ViewerViewModel, MirrorWay?>(
      (viewModel) => viewModel.sessionFor(deviceId)?.way,
    );
    final waitingUntil = context.select<ViewerViewModel, DateTime?>(
      (viewModel) => viewModel.sessionFor(deviceId)?.waitingUntil,
    );
    final picture = context.select<ViewerViewModel, MirrorPicture?>(
      (viewModel) => viewModel.picture,
    );
    final isFirstTime = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.history.isEmpty,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    void stop() {
      unawaited(viewModel.stop());
      onClose?.call();
    }

    if (pending != null && pending.deviceId == deviceId) {
      return MirrorMessage(
        icon: LucideIcons.screenShare,
        tone: .accent,
        title: l10n.replaceTitle(
          viewModel.current?.deviceName ?? '',
          pending.deviceName,
        ),
        actions: [
          MessageAction(
            label: l10n.cancel,
            onPressed: () {
              viewModel.cancelReplace();
              onClose?.call();
            },
          ),
          MessageAction(
            label: l10n.replaceConfirm(pending.deviceName),
            primary: true,
            onPressed: () => unawaited(viewModel.confirmReplace()),
          ),
        ],
      );
    }

    if (showsCableGuide) {
      return MirrorSetupFrame(
        deviceName: deviceName,
        onCancel: () {
          final isShown = viewModel.sessionFor(deviceId)?.isLive ?? false;
          viewModel.closeCableGuide();
          if (!isShown) {
            onClose?.call();
          }
        },
      );
    }

    if (showsAirplayGuide) {
      return AirplayGuideFrame(
        deviceName: deviceName,
        clock: clock,
        onCancel: () => onClose?.call(),
      );
    }

    final holdsPicture =
        phase == .streaming || phase == .starting || phase == .reconnecting;
    if (holdsPicture && picture != null) {
      return MirrorLiveFrame(
        deviceId: deviceId,
        deviceName: deviceName,
        picture: picture,
        onStop: stop,
      );
    }

    return switch (phase) {
      .ended when end != null => MirrorEndedFrame(
        deviceId: deviceId,
        deviceName: deviceName,
        end: end,
        onClose: onClose,
        clock: clock,
      ),
      .waitingForPhone => MirrorWaitingFrame(
        deviceName: deviceName,
        until: waitingUntil,
        asksEveryTime: isFirstTime,
        onCancel: stop,
        clock: clock,
      ),
      .reconnecting => MirrorMessage(
        icon: LucideIcons.wifiOff,
        title: l10n.lostTitle(deviceName),
        body: switch (way) {
          .cable => l10n.lostCableBody(deviceName),
          _ => l10n.lostBody(deviceName),
        },
        actions: [MessageAction(label: l10n.stop, onPressed: stop)],
      ),
      .starting || .streaming => MirrorMessage(
        icon: LucideIcons.screenShare,
        tone: .success,
        title: switch (way) {
          .wifi => l10n.startingTitle(deviceName),
          _ => l10n.startingCableTitle(deviceName),
        },
        body: l10n.startingBody,
        actions: [MessageAction(label: l10n.cancel, onPressed: stop)],
      ),
      _ => MirrorMessage(
        icon: LucideIcons.screenShare,
        title: l10n.requestingTitle(deviceName),
        actions: [MessageAction(label: l10n.cancel, onPressed: stop)],
      ),
    };
  }
}
