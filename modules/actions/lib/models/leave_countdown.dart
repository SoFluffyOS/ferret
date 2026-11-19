import 'package:actions/models/seconds_until.dart';

/// A phone left and this computer is about to lock: the seconds its owner
/// has to cancel.
class LeaveCountdown {
  const LeaveCountdown({
    required this.deviceId,
    required this.deviceName,
    required this.startedAt,
    required this.endsAt,
  });

  final String deviceId;
  final String deviceName;
  final DateTime startedAt;
  final DateTime endsAt;

  /// Whole seconds left at [now], never below zero.
  int secondsLeft(DateTime now) => secondsUntil(endsAt, now);
}
