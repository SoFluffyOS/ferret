import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What opens behind Sound: where the shown device's sound plays, how
/// loud, and one line on what that means or why there is none.
class SoundPanelFrame extends StatelessWidget {
  const SoundPanelFrame({super.key, required this.deviceName});

  static const _volumeSteps = 20;

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final on = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.soundOn,
    );
    final volume = context.select<ViewerViewModel, double>(
      (viewModel) => viewModel.soundVolume,
    );
    final sound = context.select<ViewerViewModel, ViewSound>(
      (viewModel) => viewModel.current?.sound ?? .off,
    );
    final way = context.select<ViewerViewModel, SoundWay>(
      (viewModel) => viewModel.soundWay,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final caption = typography.caption1.copyWith(color: palette.mutedText);
    final offers = way != .none;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: Spacing.d280),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.d8),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Spacing.d12,
                vertical: Spacing.d4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.soundTitle,
                      style: typography.base1.copyWith(color: palette.text),
                    ),
                  ),
                  if (offers)
                    Text(l10n.soundDetail(sound, on: on), style: caption),
                ],
              ),
            ),
            if (offers) ...[
              PopupRow(
                label: l10n.soundHere(ThisComputer.here),
                // Sound that plays in both places is the Wi-Fi way.
                badge: switch (way) {
                  .copies => const MirroringBetaTag(.wifiSound),
                  _ => null,
                },
                checked: on,
                onTap: () => unawaited(viewModel.setSound(true)),
              ),
              PopupRow(
                label: l10n.soundThere(deviceName),
                checked: !on,
                onTap: () => unawaited(viewModel.setSound(false)),
              ),
            ],
            if (offers && on)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.d12,
                  vertical: Spacing.d4,
                ),
                child: Semantics(
                  label: l10n.soundVolume,
                  child: FluffySlider(
                    value: volume,
                    divisions: _volumeSteps,
                    onChanged: (value) =>
                        unawaited(viewModel.setSoundVolume(value)),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                Spacing.d12,
                Spacing.d4,
                Spacing.d12,
                Spacing.d4,
              ),
              child: Text(
                l10n.soundNote(sound, way: way, on: on, device: deviceName),
                style: caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
