import 'package:flutter/widgets.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/ui/frames/browser_pair_card_frame.dart';
import 'package:handoff/ui/frames/continue_card_frame.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Handoff's spot on the home screen: a browser waiting to be allowed
/// first, then what other devices offer to continue.
class HandoffHomeFrame extends StatelessWidget {
  const HandoffHomeFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.select<HandoffViewModel, List<BrowserPairRequest>>(
      (viewModel) => viewModel.pairRequests,
    );
    final hasSuggestions = context.select<HandoffViewModel, bool>(
      (viewModel) => viewModel.suggestions.isNotEmpty,
    );

    final cards = <Widget>[
      for (final request in requests)
        BrowserPairCardFrame(key: ValueKey(request.id), request: request),
      if (hasSuggestions) const ContinueCardFrame(),
    ];
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .stretch,
      spacing: Spacing.d8,
      children: cards,
    );
  }
}
