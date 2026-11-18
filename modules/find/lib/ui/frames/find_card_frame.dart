import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:find/l10n/l10n.dart';
import 'package:find/models/models.dart';
import 'package:find/ui/widgets/widgets.dart';
import 'package:find/view_models/view_models.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card, only while something happens: "Found it" when this device
/// rings, and each ring to another device with Stop, or how it ended.
class FindCardFrame extends StatelessWidget {
  const FindCardFrame({super.key, this.showOutgoing = true});

  /// Whether rings to other devices show here too. Home leaves them to
  /// Activity.
  final bool showOutgoing;

  @override
  Widget build(BuildContext context) {
    final isRingingHere = context.select<FindViewModel, bool>(
      (viewModel) => viewModel.isRingingHere,
    );
    final outgoing = context.select<FindViewModel, List<OutgoingRing>>(
      (viewModel) => switch (showOutgoing) {
        true => viewModel.outgoing,
        false => const [],
      },
    );
    if (!isRingingHere && outgoing.isEmpty) {
      return const SizedBox.shrink();
    }

    final viewModel = context.read<FindViewModel>();

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (isRingingHere) const _RingingHere(),
        for (final (index, ring) in outgoing.indexed) ...[
          if (index > 0 || isRingingHere) Spacing.v8,
          OutgoingRingCard(
            key: ValueKey(ring.deviceId),
            ring: ring,
            onStop: () => unawaited(viewModel.stop(ring.deviceId)),
            onRingAgain: () => unawaited(viewModel.ring(ring.deviceId)),
            onDismiss: () => viewModel.dismiss(ring.deviceId),
          ),
        ],
      ],
    );
  }
}

class _RingingHere extends StatelessWidget {
  const _RingingHere();

  @override
  Widget build(BuildContext context) {
    final ring = context.select<FindViewModel, LocalRing>(
      (viewModel) => viewModel.localRing,
    );
    final l10n = context.findL10n;

    return FeatureCard(
      icon: LucideIcons.bellRing,
      title: l10n.ringingHere,
      subtitle: l10n.ringingBody(ring.requesterName),
      actions: [
        FoundItButton(
          onPressed: () => unawaited(context.read<FindViewModel>().foundIt()),
        ),
      ],
    );
  }
}
