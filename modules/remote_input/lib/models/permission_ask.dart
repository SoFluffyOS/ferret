/// A device asked for control while the system permission was missing, so
/// the owner sees why it failed and how to fix it.
class PermissionAsk {
  const PermissionAsk({
    required this.deviceId,
    required this.deviceName,
    required this.askedAt,
  });

  final String deviceId;
  final String deviceName;
  final DateTime askedAt;
}
