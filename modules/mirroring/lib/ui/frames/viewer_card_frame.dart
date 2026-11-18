import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The phones on a cable that aren't paired with Ferret, each with Show
/// screen: the one place such a phone can be picked from.
class ViewerCardFrame extends StatelessWidget {
  const ViewerCardFrame({super.key, required this.onShow});

  /// Shows a phone on the mirror stage.
  final void Function(MirrorTarget target) onShow;

  @override
  Widget build(BuildContext context) {
    final targets = context.select<ViewerViewModel, List<MirrorTarget>>(
      (viewModel) => viewModel.targets,
    );
    final l10n = context.mirroringL10n;
    if (targets.isEmpty) {
      return const SizedBox.shrink();
    }

    return FeatureCard(
      icon: LucideIcons.cable,
      title: l10n.targetsTitle,
      children: [
        for (final target in targets)
          TargetRow(
            name: target.name,
            line: l10n.targetLine(target),
            actionLabel: l10n.show,
            onAction: () => onShow(target),
          ),
      ],
    );
  }
}
