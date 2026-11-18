import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/ui/handoff_activity.dart';
import 'package:handoff/ui/widgets/widgets.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// What other devices offer to continue here, as a card. Hidden when there
/// is nothing to offer.
class ContinueCardFrame extends StatelessWidget {
  const ContinueCardFrame({super.key});

  static const _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    final suggestions = context.select<HandoffViewModel, List<Suggestion>>(
      (viewModel) => viewModel.suggestions,
    );
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.handoffL10n;

    return FeatureCard(
      icon: LucideIcons.monitorSmartphone,
      title: l10n.cardTitle,
      children: [
        for (final suggestion in suggestions.take(_maxShown))
          SuggestionTile(
            key: ValueKey(suggestion.id),
            suggestion: suggestion,
            onOpen: () => unawaited(
              HandoffActivity.open(
                context,
                context.read<HandoffViewModel>(),
                suggestion,
              ),
            ),
            onDismiss: () =>
                context.read<HandoffViewModel>().dismiss(suggestion),
          ),
      ],
    );
  }
}
