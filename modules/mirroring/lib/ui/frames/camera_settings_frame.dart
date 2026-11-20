import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// On the phone: whether computers may ask for its camera, and the way
/// back to being asked every time for those it turns on for by itself.
class CameraSettingsFrame extends StatelessWidget {
  const CameraSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final canSend = context.select<ShareViewModel, bool>(
      (viewModel) => viewModel.canSendCamera,
    );
    final enabled = context.select<ShareViewModel, bool>(
      (viewModel) => viewModel.cameraEnabled,
    );
    final alwaysCount = context.select<ShareViewModel, int>(
      (viewModel) => viewModel.cameraAlwaysCount,
    );
    final viewModel = context.read<ShareViewModel>();
    final l10n = context.mirroringL10n;
    final caption = context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.mutedText,
    );
    if (!canSend) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsCameraTitle),
        GroupedCard(
          children: [
            SettingSwitchRow(
              title: l10n.settingsCameraAllow,
              badge: const MirroringBetaTag(.wifiCamera),
              body: l10n.settingsCameraAllowBody,
              value: enabled,
              onChanged: (value) =>
                  unawaited(viewModel.setCameraEnabled(value)),
            ),
            if (alwaysCount > 0)
              GroupedCell(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      l10n.settingsCameraAlwaysCount(alwaysCount),
                      style: caption,
                    ),
                    Spacing.v8,
                    Button(
                      variant: .ghost,
                      mainAxisSize: .min,
                      label: l10n.settingsControlAskAgain,
                      onPressed: () =>
                          unawaited(viewModel.forgetCameraAlways()),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
