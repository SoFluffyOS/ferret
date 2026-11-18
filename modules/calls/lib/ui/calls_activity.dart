import 'dart:async';

import 'package:calls/l10n/l10n.dart';
import 'package:calls/models/models.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Calls' lines in Activity on a computer: one pinned line per call that is
/// ringing or going on on a connected phone, with Answer and Decline, or
/// Hang up.
List<ActivityItem> callsActivity(
  CallsLocalizations l10n,
  ActiveCallsViewModel viewModel,
) => [for (final call in viewModel.calls) _line(l10n, viewModel, call)];

ActivityItem _line(
  CallsLocalizations l10n,
  ActiveCallsViewModel viewModel,
  RemoteCall call,
) {
  final problem = viewModel.problemOf(call);

  return ActivityItem(
    id: 'calls.${call.key}',
    icon: _iconOf(call),
    title: _titleOf(l10n, call),
    detail: switch (problem) {
      final CommandOutcome problem => l10n.outcomeText(
        problem,
        call.deviceName,
      ),
      null => _detailOf(l10n, call),
    },
    at: call.startedAt,
    pinned: true,
    tone: switch (problem) {
      null => .normal,
      _ => .danger,
    },
    actions: switch (call.isRinging) {
      true => [
        ActivityAction(
          label: l10n.answer,
          primary: true,
          onPressed: () => unawaited(viewModel.answer(call)),
        ),
        ActivityAction(
          label: l10n.decline,
          onPressed: () => unawaited(viewModel.end(call)),
        ),
      ],
      false => [
        ActivityAction(
          label: l10n.hangUp,
          onPressed: () => unawaited(viewModel.end(call)),
        ),
      ],
    },
  );
}

IconData _iconOf(RemoteCall call) => switch (call.call.state) {
  .CALL_STATE_RINGING => LucideIcons.phoneIncoming,
  .CALL_STATE_DIALING => LucideIcons.phoneOutgoing,
  _ => LucideIcons.phoneCall,
};

String _titleOf(CallsLocalizations l10n, RemoteCall call) {
  final caller = l10n.callerOf(call.call);
  return switch (call.call.state) {
    .CALL_STATE_RINGING => l10n.activityRinging(caller, call.deviceName),
    .CALL_STATE_DIALING => l10n.activityDialing(caller),
    .CALL_STATE_HELD => l10n.activityOnHold(caller),
    _ => l10n.activityOnCall(caller),
  };
}

/// The number under a contact's name while it rings, as the call card did;
/// afterwards the phone the call is on, which the title no longer names.
String? _detailOf(CallsLocalizations l10n, RemoteCall call) {
  if (!call.isRinging) {
    return call.deviceName;
  }

  final details = call.call;
  if (details.contactName.isEmpty || details.number.isEmpty) {
    return null;
  }

  return details.number;
}
