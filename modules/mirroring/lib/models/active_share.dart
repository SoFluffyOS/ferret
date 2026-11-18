import 'package:ferret_mirroring/ferret_mirroring.dart';

/// The computer this phone's screen is shown on right now.
class ActiveShare {
  const ActiveShare({
    required this.deviceId,
    required this.deviceName,
    required this.startedAt,
    required this.codec,
  });

  final String deviceId;
  final String deviceName;
  final DateTime startedAt;
  final MirrorCodec codec;
}
