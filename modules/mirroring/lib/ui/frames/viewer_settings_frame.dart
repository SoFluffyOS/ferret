import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The computer's screen mirroring settings: how to start, and the history
/// of the screens it showed.
class ViewerSettingsFrame extends StatelessWidget {
  const ViewerSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.select<ViewerViewModel, List<MirrorRecord>>(
      (viewModel) => viewModel.history,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            l10n.settingsViewerHint,
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: context.palette.mutedText,
            ),
          ),
          HistoryList(
            history: history,
            onClear: () => unawaited(viewModel.clearHistory()),
          ),
        ],
      ),
    );
  }
}
