import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/frames/camera_settings_frame.dart';
import 'package:mirroring/ui/frames/control_settings_frame.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The phone's screen settings: on or off, what it can't do, its camera
/// for a computer, and the history of who saw the screen or used the
/// camera.
class ShareSettingsFrame extends StatelessWidget {
  const ShareSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<ShareViewModel, bool>(
      (viewModel) => viewModel.enabled,
    );
    final canCapture = context.select<ShareViewModel, bool>(
      (viewModel) => viewModel.canCapture,
    );
    final canSendSound = context.select<ShareViewModel, bool>(
      (viewModel) => viewModel.canSendSound,
    );
    final sendSound = context.select<ShareViewModel, bool>(
      (viewModel) => viewModel.sendSound,
    );
    final soundDenied = context.select<ShareViewModel, bool>(
      (viewModel) => viewModel.soundDenied,
    );
    final history = context.select<ShareViewModel, List<MirrorRecord>>(
      (viewModel) => viewModel.history,
    );
    final viewModel = context.read<ShareViewModel>();
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final caption = context.fluffyTheme.typography.caption1;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        GroupedCard(
          children: [
            SettingSwitchRow(
              title: l10n.settingsAllow,
              tag: l10n.experimental,
              body: l10n.settingsAllowBody,
              value: enabled,
              onChanged: (value) => unawaited(viewModel.setEnabled(value)),
            ),
            if (!canCapture)
              GroupedCell(
                child: Text(
                  l10n.settingsUnsupported(ThisComputer.handheld),
                  style: caption.copyWith(color: palette.mutedText),
                ),
              ),
            if (canCapture && canSendSound) ...[
              SettingSwitchRow(
                title: l10n.settingsSendSound,
                body: l10n.settingsSendSoundBody,
                value: sendSound,
                onChanged: (value) => unawaited(viewModel.setSendSound(value)),
              ),
              GroupedCell(
                child: Text(
                  switch (soundDenied) {
                    true => l10n.settingsSendSoundDenied,
                    false => l10n.settingsSendSoundPermission,
                  },
                  style: caption.copyWith(
                    color: switch (soundDenied) {
                      true => palette.warning,
                      false => palette.mutedText,
                    },
                  ),
                ),
              ),
            ],
            if (canCapture && !canSendSound)
              GroupedCell(
                child: Text(
                  l10n.settingsSendSoundUnsupported,
                  style: caption.copyWith(color: palette.mutedText),
                ),
              ),
            GroupedCell(
              child: Text(
                l10n.settingsPerDevice,
                style: caption.copyWith(color: palette.mutedText),
              ),
            ),
          ],
        ),
        const ControlSettingsFrame(),
        const CameraSettingsFrame(),
        HistoryList(
          history: history,
          emptyText: l10n.settingsHistoryEmptyShared,
          onClear: () => unawaited(viewModel.clearHistory()),
        ),
      ],
    );
  }
}
