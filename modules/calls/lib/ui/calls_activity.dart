import 'dart:async';

import 'package:calls/l10n/l10n.dart';
import 'package:calls/models/models.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Calls' lines in Activity on a computer: one pinned line per call that is
/// ringing or going on on a connected phone, with the caller's photo or
/// initials. Answer, Decline and Silence while it rings; a running timer
/// and Hang up once it is answered.
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
  final silenced = viewModel.isSilenced(call);

  return ActivityItem(
    id: 'calls.${call.key}',
    icon: _iconOf(call),
    leading: CallerAvatar(
      photoJpeg: call.call.photoJpeg,
      name: call.call.contactName,
      size: Spacing.d32,
    ),
    trailing: switch (call.isRinging) {
      true => null,
      false => _Timer(since: call.timerStart),
    },
    title: _titleOf(l10n, call),
    detail: switch (problem) {
      final CommandOutcome problem => l10n.outcomeText(
        problem,
        call.deviceName,
      ),
      null => _detailOf(l10n, call, silenced: silenced),
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
        if (!silenced)
          ActivityAction(
            label: l10n.silence,
            onPressed: () => unawaited(viewModel.silence(call)),
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

/// The number under a contact's name while it rings, and that the ringer
/// is silenced; afterwards the phone the call is on, which the title no
/// longer names.
String? _detailOf(
  CallsLocalizations l10n,
  RemoteCall call, {
  required bool silenced,
}) {
  if (!call.isRinging) {
    return call.deviceName;
  }

  final details = call.call;
  final parts = [
    if (details.contactName.isNotEmpty && details.number.isNotEmpty)
      details.number,
    if (silenced) l10n.silenced,
  ];
  if (parts.isEmpty) {
    return null;
  }

  return parts.join(' · ');
}

/// How long the call has lasted, ticking every second.
class _Timer extends StatelessWidget {
  const _Timer({required this.since});

  final DateTime since;

  @override
  Widget build(BuildContext context) => CallTimer(
    since: since,
    style: context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.mutedText,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}
