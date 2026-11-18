import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The line under the picture: codec, size, frames per second, latency and
/// bitrate, updated every second.
class MirrorStatusFrame extends StatelessWidget {
  const MirrorStatusFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.select<ViewerViewModel, MirrorStreamConfig?>(
      (viewModel) => viewModel.current?.config,
    );
    final stats = context.select<ViewerViewModel, ViewStats?>(
      (viewModel) => viewModel.current?.stats,
    );
    final isMirroring = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.current?.isMirroring ?? false,
    );
    if (config == null || stats == null || !isMirroring) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d12,
        vertical: Spacing.d6,
      ),
      child: Text(
        context.mirroringL10n.statusLine(config, stats),
        textAlign: .center,
        overflow: .ellipsis,
        style: context.fluffyTheme.typography.caption1.copyWith(
          color: context.palette.mutedText,
        ),
      ),
    );
  }
}
