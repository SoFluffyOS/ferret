import 'package:mirroring/models/mirror_end.dart';
import 'package:mirroring/models/mirror_role.dart';

/// One time a screen was mirrored: the audit line people see afterwards,
/// such as "MacBook viewed your screen for 12 min at 21:10".
class MirrorRecord {
  const MirrorRecord({
    required this.deviceId,
    required this.deviceName,
    required this.role,
    required this.startedAt,
    required this.endedAt,
    required this.end,
  });

  /// The other device.
  final String deviceId;
  final String deviceName;
  final MirrorRole role;
  final DateTime startedAt;
  final DateTime endedAt;
  final MirrorEnd end;

  Duration get duration => endedAt.difference(startedAt);

  Map<String, Object?> toJson() => {
    'device_id': deviceId,
    'device_name': deviceName,
    'role': role.name,
    'started_at': startedAt.millisecondsSinceEpoch,
    'ended_at': endedAt.millisecondsSinceEpoch,
    'end': end.name,
  };

  /// Null for anything that isn't a stored record.
  static MirrorRecord? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }

    final deviceId = json['device_id'];
    final deviceName = json['device_name'];
    final startedAt = json['started_at'];
    final endedAt = json['ended_at'];
    if (deviceId is! String ||
        deviceName is! String ||
        startedAt is! int ||
        endedAt is! int) {
      return null;
    }

    return MirrorRecord(
      deviceId: deviceId,
      deviceName: deviceName,
      role: MirrorRole.values.asNameMap()[json['role']] ?? .shared,
      startedAt: .fromMillisecondsSinceEpoch(startedAt),
      endedAt: .fromMillisecondsSinceEpoch(endedAt),
      end: MirrorEnd.values.asNameMap()[json['end']] ?? .viewerDone,
    );
  }
}
