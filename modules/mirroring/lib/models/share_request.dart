/// A computer waiting for this phone's owner to answer: the system prompt
/// for its screen, Ferret's own question for its camera.
class ShareRequest {
  const ShareRequest({
    required this.deviceId,
    required this.deviceName,
    required this.askedAt,
  });

  final String deviceId;
  final String deviceName;
  final DateTime askedAt;
}
