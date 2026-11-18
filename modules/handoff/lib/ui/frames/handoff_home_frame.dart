import 'package:flutter/widgets.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/ui/frames/browser_pair_card_frame.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Handoff's spot on the home screen: a browser waiting to be allowed.
/// What other devices offer to continue is in Activity.
class HandoffHomeFrame extends StatelessWidget {
  const HandoffHomeFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.select<HandoffViewModel, List<BrowserPairRequest>>(
      (viewModel) => viewModel.pairRequests,
    );
    if (requests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .stretch,
      spacing: Spacing.d8,
      children: [
        for (final request in requests)
          BrowserPairCardFrame(key: ValueKey(request.id), request: request),
      ],
    );
  }
}
