import 'package:ferret_mirroring/ferret_mirroring.dart';

/// The computer this phone's screen is shown on right now.
class ActiveShare {
  const ActiveShare({
    required this.deviceId,
    required this.deviceName,
    required this.startedAt,
    required this.codec,
    this.audioCodec,
    this.reconnecting = false,
  });

  final String deviceId;
  final String deviceName;
  final DateTime startedAt;
  final MirrorCodec codec;

  /// How this phone's sound is sent along, or null when only the screen is.
  final MirrorAudioCodec? audioCodec;

  bool get withSound => audioCodec != null;

  /// The computer dropped off: the capture is kept for a moment, so the
  /// picture picks up again without a new prompt.
  final bool reconnecting;

  ActiveShare copyWith({bool? reconnecting}) => ActiveShare(
    deviceId: deviceId,
    deviceName: deviceName,
    startedAt: startedAt,
    codec: codec,
    audioCodec: audioCodec,
    reconnecting: reconnecting ?? this.reconnecting,
  );
}
