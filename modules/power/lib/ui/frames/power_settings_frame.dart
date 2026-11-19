import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:flutter/widgets.dart';
import 'package:power/l10n/l10n.dart';
import 'package:power/view_models/power_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The Power-ups section in Settings: where this phone stands in one line,
/// and the way to the full ladder.
class PowerSettingsFrame extends StatelessWidget {
  const PowerSettingsFrame({super.key, required this.onOpen});

  /// Opens the Power-ups page.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final supported = context.select<PowerViewModel, bool>(
      (viewModel) => viewModel.status.supported,
    );
    final tier = context.select<PowerViewModel, PowerTier>(
      (viewModel) => viewModel.tier,
    );
    final l10n = context.powerL10n;
    final style = context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.mutedText,
    );

    if (!supported) {
      return SurfaceCard(child: Text(l10n.settingsUnsupported, style: style));
    }

    return GroupedCard(
      children: [
        GroupedRow(
          title: l10n.tierSummary(tier),
          trailing: Button(
            mainAxisSize: .min,
            variant: .ghost,
            label: l10n.settingsOpen,
            onPressed: onOpen,
          ),
        ),
      ],
    );
  }
}
