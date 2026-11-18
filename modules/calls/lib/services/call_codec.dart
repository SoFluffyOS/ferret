import 'package:ferret_calls/ferret_calls.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/calls.dart';

/// Turns what the phone's platform reports into Ferret's call messages.
abstract final class CallCodec {
  static CallLogEntry logEntry(PlatformCallLogEntry entry) => CallLogEntry(
    id: entry.id,
    number: entry.number,
    name: entry.name,
    type: logType(entry.type),
    dateMs: Int64(entry.dateMs),
    durationS: Int64(entry.durationSeconds),
  );

  static CallLogType logType(PlatformCallLogType type) => switch (type) {
    .incoming => .CALL_LOG_TYPE_INCOMING,
    .outgoing => .CALL_LOG_TYPE_OUTGOING,
    .missed => .CALL_LOG_TYPE_MISSED,
    .rejected => .CALL_LOG_TYPE_REJECTED,
  };

  static CallCommandStatus commandStatus(PlatformCallResult result) =>
      switch (result) {
        .ok => .CALL_COMMAND_STATUS_OK,
        .permissionMissing => .CALL_COMMAND_STATUS_PERMISSION_MISSING,
        .unsupported => .CALL_COMMAND_STATUS_UNSUPPORTED,
        .failed => .CALL_COMMAND_STATUS_FAILED,
      };

  /// What a phone with [permissions] can do. All off when it holds none or
  /// calls are turned off.
  static CallsStatus status({
    required bool enabled,
    required PlatformCallPermissions? permissions,
  }) {
    if (permissions == null) {
      return CallsStatus(enabled: enabled);
    }

    return CallsStatus(
      enabled: enabled,
      canSeeCalls: permissions.phoneState,
      canSeeNumbers: permissions.phoneState && permissions.callLog,
      canAnswer: permissions.answerCalls,
      canDial: permissions.placeCalls,
      canReadLog: permissions.callLog,
      canReadContacts: permissions.contacts,
    );
  }
}
