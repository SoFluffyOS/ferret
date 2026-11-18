import 'package:remote_input/models/control_end.dart';

/// One time a device controlled this computer: the audit line people see
/// afterwards, such as "Pixel controlled this computer for 4 min at 21:10".
class ControlRecord {
  const ControlRecord({
    required this.deviceId,
    required this.deviceName,
    required this.startedAt,
    required this.endedAt,
    required this.end,
  });

  final String deviceId;
  final String deviceName;
  final DateTime startedAt;
  final DateTime endedAt;
  final ControlEnd end;

  Duration get duration => endedAt.difference(startedAt);

  Map<String, Object?> toJson() => {
    'device_id': deviceId,
    'device_name': deviceName,
    'started_at': startedAt.millisecondsSinceEpoch,
    'ended_at': endedAt.millisecondsSinceEpoch,
    'end': end.name,
  };

  /// Null for anything that isn't a record written by [toJson].
  static ControlRecord? fromJson(Object? json) {
    if (json case {
      'device_id': final String deviceId,
      'device_name': final String deviceName,
      'started_at': final int startedAt,
      'ended_at': final int endedAt,
      'end': final String end,
    }) {
      return ControlRecord(
        deviceId: deviceId,
        deviceName: deviceName,
        startedAt: DateTime.fromMillisecondsSinceEpoch(startedAt),
        endedAt: DateTime.fromMillisecondsSinceEpoch(endedAt),
        end: ControlEnd.values.asNameMap()[end] ?? .controllerDone,
      );
    }

    return null;
  }
}
