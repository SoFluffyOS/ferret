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
  const FindCardFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final isRingingHere = context.select<FindViewModel, bool>(
      (viewModel) => viewModel.isRingingHere,
    );
    final outgoing = context.select<FindViewModel, List<OutgoingRing>>(
      (viewModel) => viewModel.outgoing,
    );
    if (!isRingingHere && outgoing.isEmpty) {
      return const SizedBox.shrink();
    }

    final viewModel = context.read<FindViewModel>();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (isRingingHere) const _RingingHere(),
          for (final (index, ring) in outgoing.indexed) ...[
            if (index > 0 || isRingingHere) Spacing.v16,
            OutgoingRingRow(
              ring: ring,
              onStop: () => unawaited(viewModel.stop(ring.deviceId)),
              onRingAgain: () => unawaited(viewModel.ring(ring.deviceId)),
              onDismiss: () => viewModel.dismiss(ring.deviceId),
            ),
          ],
        ],
      ),
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
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.bellRing,
              size: Spacing.d20,
              color: palette.accent,
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    l10n.ringingHere,
                    style: typography.base1.copyWith(color: palette.text),
                  ),
                  Spacing.vertical(Spacing.d2),
                  Text(
                    l10n.ringingBody(ring.requesterName),
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Spacing.v12,
        FoundItButton(
          onPressed: () => unawaited(context.read<FindViewModel>().foundIt()),
        ),
      ],
    );
  }
}
