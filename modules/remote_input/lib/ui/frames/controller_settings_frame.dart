import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The phone's touchpad settings: speed and scrolling direction.
class ControllerSettingsFrame extends StatelessWidget {
  const ControllerSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final speed = context.select<TouchpadViewModel, double>(
      (viewModel) => viewModel.speed,
    );
    final naturalScroll = context.select<TouchpadViewModel, bool>(
      (viewModel) => viewModel.naturalScroll,
    );
    final viewModel = context.read<TouchpadViewModel>();
    final l10n = context.remoteInputL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return GroupedCard(
      children: [
        GroupedCell(
          // The slider's name is the title above it.
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Text(
                  l10n.settingsSpeed,
                  style: typography.base1.copyWith(color: palette.text),
                ),
                Spacing.vertical(Spacing.d2),
                Text(
                  l10n.settingsSpeedBody,
                  style: typography.caption1.copyWith(color: palette.mutedText),
                ),
                FluffySlider(
                  value: speed,
                  min: RemoteInputSettings.minSpeed,
                  max: RemoteInputSettings.maxSpeed,
                  onChanged: (value) => unawaited(viewModel.setSpeed(value)),
                ),
              ],
            ),
          ),
        ),
        SettingSwitchRow(
          title: l10n.settingsNaturalScroll,
          body: l10n.settingsNaturalScrollBody,
          value: naturalScroll,
          onChanged: (value) => unawaited(viewModel.setNaturalScroll(value)),
        ),
      ],
    );
  }
}
