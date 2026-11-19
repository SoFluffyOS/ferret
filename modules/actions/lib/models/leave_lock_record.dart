/// How a lock after a phone left ended.
enum LeaveLockOutcome { locked, cancelled, failed }

/// One time this computer locked, or was about to, because a phone left.
/// Kept in memory for Activity.
class LeaveLockRecord {
  const LeaveLockRecord({
    required this.deviceId,
    required this.deviceName,
    required this.at,
    required this.outcome,
  });

  final String deviceId;
  final String deviceName;
  final DateTime at;
  final LeaveLockOutcome outcome;

  /// Unique among the records, for Activity.
  String get id => '$deviceId.left.${at.microsecondsSinceEpoch}';
}
