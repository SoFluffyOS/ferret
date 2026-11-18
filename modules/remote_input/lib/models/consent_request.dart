/// A device waiting for this computer's owner to let it take control.
class ConsentRequest {
  const ConsentRequest({
    required this.deviceId,
    required this.deviceName,
    required this.askedAt,
  });

  final String deviceId;
  final String deviceName;
  final DateTime askedAt;
}
