/// A device controlling this computer right now.
class ActiveControl {
  const ActiveControl({
    required this.deviceId,
    required this.deviceName,
    required this.startedAt,
    required this.always,
  });

  final String deviceId;
  final String deviceName;
  final DateTime startedAt;

  /// Allowed for good rather than just this once.
  final bool always;
}
