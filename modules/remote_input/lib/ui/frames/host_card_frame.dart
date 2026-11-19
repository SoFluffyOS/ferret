import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/frames/host_pending_card.dart';
import 'package:remote_input/ui/frames/host_permission_card.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// This computer's card, for what needs its owner: a device asking for
/// control, and a request that failed for a missing permission. Being
/// controlled, and having been, are lines in Activity.
class HostCardFrame extends StatelessWidget {
  const HostCardFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = context.select<HostViewModel, ConsentRequest?>(
      (viewModel) => viewModel.pending,
    );
    final permissionAsk = context.select<HostViewModel, PermissionAsk?>(
      (viewModel) => viewModel.permissionAsk,
    );
    final cards = [
      if (pending != null) HostPendingCard(pending: pending),
      if (permissionAsk != null) HostPermissionCard(ask: permissionAsk),
    ];
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, card) in cards.indexed) ...[
          if (index > 0) Spacing.v8,
          card,
        ],
      ],
    );
  }
}
