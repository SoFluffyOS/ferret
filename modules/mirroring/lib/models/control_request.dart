/// A computer that shows this phone's screen asks to tap and type on it,
/// and waits for the owner's answer.
class ControlRequest {
  const ControlRequest({
    required this.deviceId,
    required this.deviceName,
    required this.askedAt,
  });

  final String deviceId;
  final String deviceName;
  final DateTime askedAt;
}
