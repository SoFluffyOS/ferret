import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/view_models/view_models.dart';

/// Remote input's lines in Activity on a computer: a pinned "Pixel is
/// controlling this Mac" with Stop for as long as it lasts, then one line
/// saying that it did and for how long, with a ✕ to tidy it away.
/// [thisComputer] picks the word for
/// this device: this Mac, this PC or this computer.
List<ActivityItem> remoteInputActivity(
  RemoteInputLocalizations l10n,
  HostViewModel viewModel, {
  required HostKind thisComputer,
}) {
  final active = viewModel.active;
  if (active != null) {
    return [_controlling(l10n, viewModel, active, thisComputer)];
  }

  return [?_controlled(l10n, viewModel, thisComputer)];
}

ActivityItem _controlling(
  RemoteInputLocalizations l10n,
  HostViewModel viewModel,
  ActiveControl active,
  HostKind thisComputer,
) => ActivityItem(
  id: 'remote_input.active',
  icon: LucideIcons.mousePointer2,
  title: l10n.activityControlling(active.deviceName, thisComputer.name),
  at: active.startedAt,
  pinned: true,
  tone: .warning,
  actions: [
    ActivityAction(
      label: l10n.activityStop,
      onPressed: () => unawaited(viewModel.stop()),
    ),
  ],
);

ActivityItem? _controlled(
  RemoteInputLocalizations l10n,
  HostViewModel viewModel,
  HostKind thisComputer,
) {
  final record = viewModel.lastRecord;
  if (record == null) {
    return null;
  }

  return ActivityItem(
    id: 'remote_input.record.${record.startedAt.millisecondsSinceEpoch}',
    icon: LucideIcons.mousePointer2,
    title: l10n.activityControlled(record.deviceName, thisComputer.name),
    detail: l10n.activityControlledFor(record.duration.inMinutes),
    at: record.endedAt,
    tone: .muted,
    onDismiss: viewModel.dismissRecord,
  );
}
