import 'package:protocol/calls.dart';

/// Why a phone's recent calls could not be read.
enum CallLogProblem {
  /// The phone is not connected or did not answer.
  unreachable,

  /// The phone may not read its call history.
  permissionMissing,

  /// Calls are turned off on the phone.
  disabled,
}

/// A phone's recent calls, or the reason there are none.
class CallLogResult {
  const CallLogResult(this.entries, {this.problem});

  const CallLogResult.failed(CallLogProblem this.problem) : entries = const [];

  /// Newest first.
  final List<CallLogEntry> entries;
  final CallLogProblem? problem;
}
