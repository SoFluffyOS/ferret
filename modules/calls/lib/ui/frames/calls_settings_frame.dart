import 'package:calls/l10n/l10n.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Calls settings on a computer: the incoming call notice, and where the
/// audio is.
class CallsSettingsFrame extends StatelessWidget {
  const CallsSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final showIncoming = context.select<CallsSettingsViewModel, bool>(
      (viewModel) => viewModel.showIncoming,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          ToggleRow(
            title: l10n.showIncoming,
            detail: l10n.showIncomingDetail,
            value: showIncoming,
            onChanged: context.read<CallsSettingsViewModel>().setShowIncoming,
          ),
          Spacing.v12,
          Text(
            l10n.settingsAudio,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        ],
      ),
    );
  }
}
