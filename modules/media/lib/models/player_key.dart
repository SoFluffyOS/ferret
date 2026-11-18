/// Names one player on one device.
final class PlayerKey {
  const PlayerKey(this.deviceId, this.playerId);

  final String deviceId;
  final String playerId;

  @override
  bool operator ==(Object other) =>
      other is PlayerKey &&
      other.deviceId == deviceId &&
      other.playerId == playerId;

  @override
  int get hashCode => Object.hash(deviceId, playerId);

  @override
  String toString() => 'PlayerKey($deviceId, $playerId)';
}
