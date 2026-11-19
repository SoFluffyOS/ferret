import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/ui/action_icon.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:protocol/actions.dart';

/// The computer's lines in Activity: what each device ran here and how it
/// went, with the last line a custom action printed.
List<ActivityItem> recordActivity(
  ActionsLocalizations l10n,
  List<ActionRecord> records, {
  required int commandSeconds,
  required void Function(String id) onDismiss,
}) => [
  for (final record in records)
    ActivityItem(
      id: 'actions.ran.${record.id}',
      icon: actionIcon(record.kind),
      title: l10n.recordTitle(
        l10n.actionLabel(record.kind, record.title),
        record.deviceName,
      ),
      detail: l10n.recordDetailOf(record, commandSeconds: commandSeconds),
      at: record.at,
      deviceId: record.deviceId,
      tone: switch (record.result) {
        .RUN_RESULT_DONE => .success,
        _ => .warning,
      },
      onDismiss: () => onDismiss(record.id),
    ),
];

/// The asking device's lines in Activity: pinned while the computer
/// answers, then what came of it, with a ✕ to tidy it away.
List<ActivityItem> outgoingActivity(
  ActionsLocalizations l10n,
  List<OutgoingAction> outgoing, {
  required void Function(String id) onDismiss,
}) => [for (final asked in outgoing) _outgoingLine(l10n, asked, onDismiss)];

ActivityItem _outgoingLine(
  ActionsLocalizations l10n,
  OutgoingAction asked,
  void Function(String id) onDismiss,
) {
  final device = asked.deviceName;
  final action = asked.action;
  final label = l10n.actionLabel(action.kind, action.title);
  final result = asked.result;
  if (result == null) {
    return ActivityItem(
      id: asked.id,
      icon: actionIcon(action.kind),
      title: l10n.outAsking(device, label),
      detail: switch (action.confirm) {
        true => l10n.outCountingDown(device),
        false => l10n.outAskingDetail(device),
      },
      at: asked.at,
      deviceId: asked.deviceId,
      pinned: true,
      tone: .accent,
    );
  }

  return ActivityItem(
    id: asked.id,
    icon: actionIcon(action.kind),
    title: switch (result) {
      .RUN_RESULT_DONE => _doneTitle(l10n, device, action),
      .RUN_RESULT_DENIED => l10n.outDenied(device),
      .RUN_RESULT_NOT_ANSWERED => l10n.outNotAnswered(device),
      .RUN_RESULT_BUSY => l10n.outBusy(device),
      .RUN_RESULT_TURNED_OFF => l10n.outTurnedOff(device),
      .RUN_RESULT_UNKNOWN_ACTION => l10n.outUnknown(device),
      .RUN_RESULT_CANCELLED => l10n.outCancelled(device),
      .RUN_RESULT_TIMED_OUT => l10n.outTimedOut(label, device),
      _ => l10n.outFailed(device),
    },
    detail: switch ((result, asked.exitCode)) {
      (.RUN_RESULT_NOT_ANSWERED, _) => l10n.outNotAnsweredDetail,
      (.RUN_RESULT_TURNED_OFF, _) => l10n.outTurnedOffDetail,
      (.RUN_RESULT_TIMED_OUT, _) => l10n.outTimedOutDetail,
      (.RUN_RESULT_FAILED, final code?) => l10n.outFailedCode(label, code),
      _ => null,
    },
    at: asked.at,
    deviceId: asked.deviceId,
    tone: switch (result) {
      .RUN_RESULT_DONE => .success,
      _ => .warning,
    },
    onDismiss: () => onDismiss(asked.id),
  );
}

String _doneTitle(ActionsLocalizations l10n, String device, Action action) =>
    switch (action.kind) {
      .ACTION_KIND_SLEEP => l10n.outSleep(device),
      .ACTION_KIND_RESTART => l10n.outRestart(device),
      .ACTION_KIND_SHUT_DOWN => l10n.outShutDown(device),
      _ => l10n.outCustom(device, l10n.actionLabel(action.kind, action.title)),
    };
