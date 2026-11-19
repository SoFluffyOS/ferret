import 'package:actions/models/offered_action.dart';

/// This computer is about to restart or shut down because a device asked:
/// the seconds its owner has to cancel.
class ActionCountdown {
  const ActionCountdown({
    required this.deviceId,
    required this.deviceName,
    required this.action,
    required this.startedAt,
    required this.endsAt,
  });

  final String deviceId;
  final String deviceName;
  final OfferedAction action;
  final DateTime startedAt;
  final DateTime endsAt;

  /// Whole seconds left at [now], never below zero.
  int secondsLeft(DateTime now) {
    final left = endsAt.difference(now);
    if (left <= Duration.zero) {
      return 0;
    }

    return (left.inMilliseconds / Duration.millisecondsPerSecond).ceil();
  }
}
