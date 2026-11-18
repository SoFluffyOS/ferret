import 'package:drop/models/quickshare_problem.dart';

/// Whether phones can find this device in Quick Share right now.
class QuickShareReceiveState {
  const QuickShareReceiveState({
    this.isOn = false,
    this.isStarting = false,
    this.until,
    this.name = '',
    this.problem,
  });

  final bool isOn;
  final bool isStarting;

  /// When this device stops being visible.
  final DateTime? until;

  /// The name phones show for this device.
  final String name;

  /// Why the last attempt to turn it on failed.
  final QuickShareProblem? problem;

  /// Time left at [now], or null when it is off.
  Duration? remaining(DateTime now) {
    final end = until;
    if (!isOn || end == null) {
      return null;
    }

    final left = end.difference(now);
    if (left.isNegative) {
      return Duration.zero;
    }

    return left;
  }
}
