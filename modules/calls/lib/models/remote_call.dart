import 'package:protocol/calls.dart';

/// A call on a connected phone, as this device sees it.
class RemoteCall {
  const RemoteCall({
    required this.deviceId,
    required this.deviceName,
    required this.call,
    required this.startedAt,
    this.connectedAt,
  });

  final String deviceId;
  final String deviceName;
  final Call call;

  /// When the call started ringing or dialing, in this device's clock.
  final DateTime startedAt;

  /// When the call was picked up, in this device's clock.
  final DateTime? connectedAt;

  String get id => call.id;

  /// Unique across phones.
  String get key => '$deviceId/${call.id}';

  bool get isRinging => call.state == CallState.CALL_STATE_RINGING;

  bool get isEnded => call.state == CallState.CALL_STATE_ENDED;

  bool get isIncoming =>
      call.direction == CallDirection.CALL_DIRECTION_INCOMING;

  bool get wasMissed => call.outcome == CallOutcome.CALL_OUTCOME_MISSED;

  /// What the call timer counts from.
  DateTime get timerStart => connectedAt ?? startedAt;

  RemoteCall withCall(Call updated) => RemoteCall(
    deviceId: deviceId,
    deviceName: deviceName,
    call: updated,
    startedAt: startedAt,
    connectedAt: connectedAt,
  );
}
