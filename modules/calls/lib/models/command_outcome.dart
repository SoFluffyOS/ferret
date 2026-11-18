import 'package:protocol/calls.dart';

/// How a call command ended, as the person who tapped the button sees it.
enum CommandOutcome {
  ok,

  /// The call is already gone.
  noCall,

  /// Calls are turned off on the phone.
  disabled,

  /// The phone lacks the permission the command needs.
  permissionMissing,

  /// The phone's Android version can't do it.
  unsupported,

  invalidNumber,

  /// The phone tried and Android refused.
  failed,

  /// The phone is not connected or did not answer.
  unreachable;

  bool get isOk => this == ok;

  static CommandOutcome fromStatus(CallCommandStatus status) =>
      switch (status) {
        .CALL_COMMAND_STATUS_OK => ok,
        .CALL_COMMAND_STATUS_NO_CALL => noCall,
        .CALL_COMMAND_STATUS_DISABLED => disabled,
        .CALL_COMMAND_STATUS_PERMISSION_MISSING => permissionMissing,
        .CALL_COMMAND_STATUS_UNSUPPORTED => unsupported,
        .CALL_COMMAND_STATUS_INVALID_NUMBER => invalidNumber,
        _ => failed,
      };
}
