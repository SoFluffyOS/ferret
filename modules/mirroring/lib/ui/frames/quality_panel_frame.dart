import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What opens behind the quality mark: how the picture is doing in one
/// word, three presets, and the numbers for those who ask.
class QualityPanelFrame extends StatelessWidget {
  const QualityPanelFrame({super.key, required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final preset = context.select<ViewerViewModel, QualityPreset>(
      (viewModel) => viewModel.preset,
    );
    final stats = context.select<ViewerViewModel, ViewStats>(
      (viewModel) => viewModel.current?.stats ?? const ViewStats(),
    );
    final config = context.select<ViewerViewModel, MirrorStreamConfig?>(
      (viewModel) => viewModel.current?.config,
    );
    final way = context.select<ViewerViewModel, MirrorWay?>(
      (viewModel) => viewModel.current?.way,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final caption = typography.caption1.copyWith(color: palette.mutedText);
    final presetNote = switch (way) {
      .cable => l10n.presetRestarts,
      .airplay => l10n.presetAirplay,
      _ => l10n.presetNextTime(deviceName),
    };

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
                      l10n.pictureTitle,
                      style: typography.base1.copyWith(color: palette.text),
                    ),
                  ),
                  Text(l10n.qualityName(stats.quality), style: caption),
                  Spacing.h8,
                  QualityMark(quality: stats.quality),
                ],
              ),
            ),
            if (way != .airplay)
              for (final choice in QualityPreset.values)
                PopupRow(
                  label: l10n.presetName(choice),
                  detail: l10n.presetBody(choice),
                  checked: choice == preset,
                  onTap: () => unawaited(viewModel.setPreset(choice)),
                ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.d12,
                Spacing.d4,
                Spacing.d12,
                Spacing.d4,
              ),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(presetNote, style: caption),
                  if (config?.codec == .jpeg) ...[
                    Spacing.v4,
                    Text(l10n.basicPicture, style: caption),
                  ],
                  if (config != null) ...[
                    Spacing.v8,
                    Text(l10n.statusLine(config, stats), style: caption),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
