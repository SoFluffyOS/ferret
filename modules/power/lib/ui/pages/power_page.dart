import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:power/l10n/l10n.dart';
import 'package:power/ui/frames/frames.dart';
import 'package:power/view_models/power_view_model.dart';
import 'package:provider/provider.dart';

/// The full Power-ups screen: the ladder, the Shizuku setup, and root.
class PowerPage extends StatelessWidget {
  const PowerPage({super.key, required this.viewModel});

  final PowerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.powerL10n;

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: FerretPage(
        title: l10n.title,
        backLabel: l10n.back,
        children: [
          SectionTitle(l10n.ladderTitle),
          const PowerLadderFrame(),
          SectionTitle(l10n.shizukuTitle),
          const PowerShizukuFrame(),
          SectionTitle(l10n.rootTitle),
          const PowerRootFrame(),
        ],
      ),
    );
  }
}
