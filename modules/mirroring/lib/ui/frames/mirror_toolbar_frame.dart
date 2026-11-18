import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The mirror page's top row: Back, the phone's name, Fit or 1:1, full
/// screen where the window can, and Stop.
class MirrorToolbarFrame extends StatelessWidget {
  const MirrorToolbarFrame({super.key, required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final isLive = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.current?.isLive ?? false,
    );
    final isMirroring = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.current?.isMirroring ?? false,
    );
    final actualSize = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.actualSize,
    );
    final canFullScreen = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.canFullScreen,
    );
    final isFullScreen = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.isFullScreen,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final (sizeLabel, sizeTooltip) = switch (actualSize) {
      true => (l10n.fit, l10n.fitTooltip),
      false => (l10n.actualSize, l10n.actualSizeTooltip),
    };
    final fullScreenLabel = switch (isFullScreen) {
      true => l10n.exitFullScreen,
      false => l10n.fullScreen,
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.d12,
        Spacing.d12,
        Spacing.d12,
        Spacing.d4,
      ),
      child: Row(
        children: [
          Tappable(
            tooltip: l10n.back,
            onTap: () => unawaited(Navigator.of(context).maybePop()),
            child: Padding(
              padding: EdgeInsets.all(Spacing.d4),
              child: Icon(
                LucideIcons.chevronLeft,
                size: Spacing.d20,
                color: palette.text,
              ),
            ),
          ),
          Spacing.h4,
          Expanded(
            child: Text(
              deviceName,
              style: context.fluffyTheme.typography.title2.copyWith(
                color: palette.text,
              ),
              overflow: .ellipsis,
            ),
          ),
          if (isMirroring)
            Button(
              variant: .ghost,
              label: sizeLabel,
              tooltip: sizeTooltip,
              onPressed: () => unawaited(viewModel.setActualSize(!actualSize)),
            ),
          if (isMirroring && canFullScreen)
            Button(
              variant: .ghost,
              label: fullScreenLabel,
              onPressed: () =>
                  unawaited(viewModel.setFullScreen(!isFullScreen)),
            ),
          if (isLive) ...[
            Spacing.h4,
            Button(
              variant: .ghost,
              label: l10n.stop,
              onPressed: () => unawaited(viewModel.stop()),
            ),
          ],
        ],
      ),
    );
  }
}
