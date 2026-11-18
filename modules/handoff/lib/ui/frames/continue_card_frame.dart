import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/ui/widgets/widgets.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card: what other devices offer to continue here. Hidden when
/// there is nothing to offer.
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

    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.handoffL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            l10n.cardTitle,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
          Spacing.v4,
          for (final suggestion in suggestions.take(_maxShown))
            SuggestionTile(
              key: ValueKey(suggestion.id),
              suggestion: suggestion,
              onOpen: () => _open(context, suggestion),
              onDismiss: () =>
                  context.read<HandoffViewModel>().dismiss(suggestion),
            ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, Suggestion suggestion) async {
    final l10n = context.handoffL10n;
    final result = await context.read<HandoffViewModel>().open(suggestion);
    if (!context.mounted) {
      return;
    }

    switch (result) {
      case .opened:
        return;
      case .deferred:
        context.toast(l10n.openDeferred);
      case .failed:
        context.toastError(l10n.openFailed);
    }
  }
}
