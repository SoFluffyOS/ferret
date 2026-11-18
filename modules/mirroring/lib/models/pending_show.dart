/// A device the person asked to show while another one is on screen:
/// asked about first, never swapped silently.
class PendingShow {
  const PendingShow({required this.deviceId, required this.deviceName});

  final String deviceId;
  final String deviceName;

  @override
  bool operator ==(Object other) =>
      other is PendingShow && other.deviceId == deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}
