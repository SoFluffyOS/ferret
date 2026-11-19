import 'package:phone_camera/models/picture_kind.dart';

/// On a phone: a computer's request for a picture, waiting for the owner's
/// Take photo or Not now.
class CaptureAsk {
  const CaptureAsk({
    required this.requestId,
    required this.deviceId,
    required this.kind,
    required this.receivedAt,
    this.isCapturing = false,
  });

  final String requestId;

  /// The computer that asked.
  final String deviceId;
  final PictureKind kind;
  final DateTime receivedAt;

  /// The camera is open for it right now.
  final bool isCapturing;

  CaptureAsk capturing() => CaptureAsk(
    requestId: requestId,
    deviceId: deviceId,
    kind: kind,
    receivedAt: receivedAt,
    isCapturing: true,
  );
}
