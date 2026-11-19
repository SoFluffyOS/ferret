import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/frames/quality_panel_frame.dart';
import 'package:mirroring/ui/frames/sound_panel_frame.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The mirror toolbar for the device on the stage: which buttons it gets
/// from what the device takes, and what each one does.
class MirrorToolbarFrame extends StatelessWidget {
  const MirrorToolbarFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.place,
    required this.onStop,
    this.onPopup,
  });

  static const _moreButtons = <DeviceButton>[
    .notifications,
    .volumeUp,
    .volumeDown,
    .power,
  ];

  final String deviceId;
  final String deviceName;
  final ToolbarPlace place;
  final VoidCallback onStop;
  final ValueChanged<bool>? onPopup;

  @override
  Widget build(BuildContext context) {
    final canPress = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.canPress,
    );
    final canText = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.canText,
    );
    final viewOnly = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.abilities.isEmpty,
    );
    final canFullScreen = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.canFullScreen,
    );
    final isFullScreen = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.isFullScreen,
    );
    final pinned = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.toolbarPinned,
    );
    final quality = context.select<ViewerViewModel, ViewQuality>(
      (viewModel) => viewModel.current?.stats.quality ?? .good,
    );
    final canPlaySound = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.canPlaySound,
    );
    final soundOn = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.soundOn,
    );
    final sound = context.select<ViewerViewModel, ViewSound>(
      (viewModel) => viewModel.current?.sound ?? .off,
    );
    final soundWay = context.select<ViewerViewModel, SoundWay>(
      (viewModel) => viewModel.soundWay,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    // Only the window's bar fades, so only there is keeping it a choice.
    final canPin = place == .bar;
    final hasMore = canPress || canPlaySound || place != .beside;

    return MirrorToolbar(
      place: place,
      quality: quality,
      isFullScreen: isFullScreen,
      pinned: switch (canPin) {
        true => pinned,
        false => null,
      },
      onPinned: (value) => unawaited(viewModel.setToolbarPinned(value)),
      onPopup: onPopup,
      moreButtons: switch (canPress) {
        true => _moreButtons,
        false => const [],
      },
      items: [
        if (canPress) ...const [.back, .home, .recents, .rotate],
        if (viewOnly) .viewOnly,
        .screenshot,
        if (canText) .keyboard,
        .quality,
        if (canFullScreen) .fullScreen,
        if (hasMore) .more,
        .stop,
      ],
      onButton: viewModel.press,
      onItem: (item) => switch (item) {
        .back => viewModel.press(.back),
        .home => viewModel.press(.home),
        .recents => viewModel.press(.recents),
        .rotate => viewModel.press(.rotate),
        .screenshot => unawaited(viewModel.screenshot()),
        .keyboard => viewModel.openTextField(),
        .fullScreen => unawaited(viewModel.setFullScreen(!isFullScreen)),
        .stop => onStop(),
        .viewOnly || .quality || .more => null,
      },
      qualityPanel: (_) => QualityPanelFrame(deviceName: deviceName),
      soundPanel: switch (canPlaySound) {
        true => (_) => SoundPanelFrame(deviceName: deviceName),
        false => null,
      },
      soundDetail: switch (soundWay) {
        .none => l10n.soundDetailNone,
        _ => l10n.soundDetail(sound, on: soundOn),
      },
      soundMuted: !soundOn || sound != .playing,
      viewOnlyPanel: (_) => _ViewOnlyPanel(
        deviceId: deviceId,
        deviceName: deviceName,
      ),
    );
  }
}

/// Why clicks do nothing, said once, with the way to get control.
class _ViewOnlyPanel extends StatelessWidget {
  const _ViewOnlyPanel({required this.deviceId, required this.deviceName});

  final String deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final way = context.select<ViewerViewModel, MirrorWay?>(
      (viewModel) => viewModel.current?.way,
    );
    final cableOffers = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.cableOffers(deviceId),
    );
    final hasCable = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.hasCable,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    final overAirplay = way == .airplay;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: Spacing.d280),
      child: Padding(
        padding: EdgeInsets.all(Spacing.d12),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(
              switch (overAirplay) {
                true => l10n.viewOnlyAirplayBody,
                false => l10n.viewOnlyBody(deviceName),
              },
              style: context.fluffyTheme.typography.caption1.copyWith(
                color: context.palette.text,
              ),
            ),
            if (cableOffers)
              _link(
                context,
                l10n.controlWithCable,
                () => unawaited(viewModel.controlWithCable(deviceId)),
              ),
            if (!cableOffers && hasCable && !overAirplay)
              _link(
                context,
                l10n.how,
                () => viewModel.openCableGuide(deviceId),
              ),
          ],
        ),
      ),
    );
  }

  Widget _link(BuildContext context, String label, VoidCallback onTap) =>
      Padding(
        padding: EdgeInsets.only(top: Spacing.d8),
        child: Tappable(
          onTap: onTap,
          child: Text(
            label,
            style: context.fluffyTheme.typography.base2.copyWith(
              color: context.palette.link,
            ),
          ),
        ),
      );
}
