import 'package:calls/l10n/generated/calls_localizations.dart';
import 'package:calls/models/models.dart';
import 'package:protocol/calls.dart';

/// Words for calls, their state and what went wrong.
extension CallLabels on CallsLocalizations {
  /// The contact's name, else the number, else "Unknown caller".
  String callerOf(Call call) {
    if (call.contactName.isNotEmpty) {
      return call.contactName;
    }

    if (call.number.isNotEmpty) {
      return call.number;
    }

    return unknownCaller;
  }

  String stateOf(RemoteCall call) => switch (call.call.state) {
    .CALL_STATE_RINGING => incomingOn(call.deviceName),
    .CALL_STATE_DIALING => callingOn(call.deviceName),
    .CALL_STATE_HELD => onHoldOn(call.deviceName),
    _ => onCallOn(call.deviceName),
  };

  /// Why a command did not work and what to do about it. Empty for
  /// [CommandOutcome.ok].
  String outcomeText(CommandOutcome outcome, String device) =>
      switch (outcome) {
        .ok => '',
        .noCall => outcomeNoCall,
        .disabled => outcomeDisabled(device),
        .permissionMissing => outcomePermission(device),
        .unsupported => outcomeUnsupported(device),
        .invalidNumber => outcomeInvalidNumber,
        .failed => outcomeFailed(device),
        .unreachable => outcomeUnreachable(device),
      };

  String logProblemText(CallLogProblem problem, String device) =>
      switch (problem) {
        .unreachable => logUnreachable(device),
        .permissionMissing => logPermission(device),
        .disabled => logDisabled(device),
      };

  String logTypeOf(CallLogType type) => switch (type) {
    .CALL_LOG_TYPE_OUTGOING => typeOutgoing,
    .CALL_LOG_TYPE_MISSED => typeMissed,
    .CALL_LOG_TYPE_REJECTED => typeRejected,
    _ => typeIncoming,
  };

  /// The entry's name, else its number, else "Private number".
  String logCallerOf(CallLogEntry entry) {
    if (entry.name.isNotEmpty) {
      return entry.name;
    }

    if (entry.number.isNotEmpty) {
      return entry.number;
    }

    return privateNumber;
  }
}

/// A call's length as `m:ss`, or `h:mm:ss` from one hour.
String formatCallDuration(Duration duration) {
  final clamped = switch (duration.isNegative) {
    true => Duration.zero,
    false => duration,
  };
  final seconds = (clamped.inSeconds % 60).toString().padLeft(2, '0');
  if (clamped.inHours == 0) {
    return '${clamped.inMinutes}:$seconds';
  }

  final minutes = (clamped.inMinutes % 60).toString().padLeft(2, '0');
  return '${clamped.inHours}:$minutes:$seconds';
}
