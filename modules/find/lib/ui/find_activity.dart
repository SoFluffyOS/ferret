import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:find/l10n/l10n.dart';
import 'package:find/ui/widgets/widgets.dart';
import 'package:find/view_models/view_models.dart';

/// Find's lines in Activity: each ring to another device, pinned with Stop
/// while it rings, then how it ended with Ring again.
List<ActivityItem> findActivity(
  FindLocalizations l10n,
  FindViewModel viewModel,
) => [
  for (final ring in viewModel.outgoing)
    ActivityItem(
      id: 'find.${ring.deviceId}',
      icon: outgoingIcon(ring.phase),
      tone: outgoingTone(ring.phase),
      title: l10n.outgoingTitle(ring),
      detail: l10n.outgoingDetail(ring),
      at: ring.startedAt,
      pinned: ring.isActive,
      actions: [
        switch (ring.isActive) {
          true => ActivityAction(
            label: l10n.stop,
            onPressed: () => unawaited(viewModel.stop(ring.deviceId)),
          ),
          false => ActivityAction(
            label: l10n.ringAgain,
            onPressed: () => unawaited(viewModel.ring(ring.deviceId)),
          ),
        },
      ],
    ),
];
