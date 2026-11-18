import 'package:drop/models/localsend_problem.dart';

/// Whether LocalSend devices can send to this one right now.
class LocalSendReceiveState {
  const LocalSendReceiveState({
    this.isOn = false,
    this.isStarting = false,
    this.until,
    this.alias = '',
    this.port,
    this.problem,
  });

  final bool isOn;

  /// Turning on: making the certificate the first time takes a moment.
  final bool isStarting;

  /// When the receive window closes, or null when it stays open.
  final DateTime? until;

  /// The name LocalSend devices see for this one.
  final String alias;

  /// The port in use, shown when it isn't LocalSend's usual one.
  final int? port;

  /// Why the last attempt to turn it on failed.
  final LocalSendProblem? problem;

  /// Time left in the window at [now], or null when it stays open or is
  /// off.
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
