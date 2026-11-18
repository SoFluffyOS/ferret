import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The phone's screen settings: on or off, what it can't do, and the
/// history of who saw the screen.
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
    final history = context.select<ShareViewModel, List<MirrorRecord>>(
      (viewModel) => viewModel.history,
    );
    final viewModel = context.read<ShareViewModel>();
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final caption = context.fluffyTheme.typography.caption1;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          SettingSwitchRow(
            title: l10n.settingsAllow,
            tag: l10n.experimental,
            body: l10n.settingsAllowBody,
            value: enabled,
            onChanged: (value) => unawaited(viewModel.setEnabled(value)),
          ),
          if (!canCapture) ...[
            Spacing.v4,
            Text(
              l10n.settingsUnsupported,
              style: caption.copyWith(color: palette.mutedText),
            ),
          ],
          Spacing.v4,
          Text(
            l10n.settingsPerDevice,
            style: caption.copyWith(color: palette.mutedText),
          ),
          HistoryList(
            history: history,
            emptyText: l10n.settingsHistoryEmptyShared,
            onClear: () => unawaited(viewModel.clearHistory()),
          ),
        ],
      ),
    );
  }
}
