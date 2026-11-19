import 'package:protocol/actions.dart';

/// An action this device asked a computer to run: waiting, or how it went.
class OutgoingAction {
  const OutgoingAction({
    required this.deviceId,
    required this.deviceName,
    required this.action,
    required this.at,
    this.result,
    this.exitCode,
  });

  final String deviceId;
  final String deviceName;
  final Action action;

  /// When it was asked, or answered once [result] is in.
  final DateTime at;

  /// Null while the computer hasn't answered, such as while it asks its
  /// owner or counts down.
  final RunResult? result;

  /// How a custom action's command ended, when it ran to its end.
  final int? exitCode;

  bool get isWaiting => result == null;

  String get id => 'actions.out.$deviceId.${action.id}';
}
