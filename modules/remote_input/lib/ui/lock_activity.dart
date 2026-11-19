import 'package:feature_kit/feature_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';

/// The phone's lines in Activity for "Lock MacBook Air": pinned while the
/// computer answers, then what came of it, with a ✕ to tidy it away.
List<ActivityItem> lockActivity(
  RemoteInputLocalizations l10n,
  List<OutgoingLock> locks, {
  required void Function(String deviceId) onDismiss,
}) => [for (final lock in locks) _line(l10n, lock, onDismiss)];

ActivityItem _line(
  RemoteInputLocalizations l10n,
  OutgoingLock lock,
  void Function(String deviceId) onDismiss,
) {
  final name = lock.deviceName;
  final result = lock.result;
  if (result == null) {
    return ActivityItem(
      id: 'remote_input.lock.${lock.deviceId}',
      icon: LucideIcons.lock,
      title: l10n.lockAsking(name),
      detail: l10n.lockAskingDetail(name),
      at: lock.at,
      deviceId: lock.deviceId,
      pinned: true,
      tone: .accent,
    );
  }

  return ActivityItem(
    id: 'remote_input.lock.${lock.deviceId}',
    icon: switch (result) {
      .LOCK_RESULT_LOCKED => LucideIcons.lock,
      _ => LucideIcons.lockOpen,
    },
    title: switch (result) {
      .LOCK_RESULT_LOCKED => l10n.lockLocked(name),
      .LOCK_RESULT_DENIED => l10n.lockDenied(name),
      .LOCK_RESULT_TIMEOUT => l10n.lockTimedOut(name),
      .LOCK_RESULT_BUSY => l10n.lockBusy(name),
      .LOCK_RESULT_TURNED_OFF => l10n.lockTurnedOff(name),
      _ => l10n.lockFailed(name),
    },
    detail: switch (result) {
      .LOCK_RESULT_TIMEOUT => l10n.lockTimedOutDetail,
      .LOCK_RESULT_TURNED_OFF => l10n.lockTurnedOffDetail,
      _ => null,
    },
    at: lock.at,
    deviceId: lock.deviceId,
    tone: switch (result) {
      .LOCK_RESULT_LOCKED => .success,
      _ => .warning,
    },
    onDismiss: () => onDismiss(lock.deviceId),
  );
}
