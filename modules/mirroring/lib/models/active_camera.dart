import 'package:ferret_mirroring/ferret_mirroring.dart';

/// The computer that uses this phone's camera right now.
class ActiveCamera {
  const ActiveCamera({
    required this.deviceId,
    required this.deviceName,
    required this.startedAt,
    required this.lens,
    this.withSound = false,
  });

  final String deviceId;
  final String deviceName;
  final DateTime startedAt;

  /// The camera that is on.
  final MirrorLens lens;

  /// The microphone goes along with the pictures.
  final bool withSound;

  ActiveCamera copyWith({MirrorLens? lens}) => ActiveCamera(
    deviceId: deviceId,
    deviceName: deviceName,
    startedAt: startedAt,
    lens: lens ?? this.lens,
    withSound: withSound,
  );
}
