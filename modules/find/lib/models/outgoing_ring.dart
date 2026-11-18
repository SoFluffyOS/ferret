/// Where ringing another device stands, as this device knows it.
enum OutgoingPhase {
  /// Asked, waiting for the answer.
  requesting,
  ringing,

  /// Someone tapped "Found it" on it.
  found,
  timedOut,

  /// Stopped from this device.
  stoppedHere,

  /// Stopped from another of the person's devices.
  stoppedElsewhere,

  /// It couldn't play a sound at all.
  noSound,

  /// It didn't answer.
  unreachable,

  /// Ferret on it can't ring, such as an older version.
  notSupported,

  /// The connection dropped while it rang. It keeps ringing until its own
  /// timeout.
  lostConnection;

  bool get isActive => this == requesting || this == ringing;

  bool get isProblem =>
      this == noSound ||
      this == unreachable ||
      this == notSupported ||
      this == lostConnection;
}

/// Ringing one other device.
class OutgoingRing {
  const OutgoingRing({
    required this.deviceId,
    required this.deviceName,
    required this.phase,
    required this.startedAt,
    this.endsAt,
    this.muted = false,
  });

  final String deviceId;
  final String deviceName;
  final OutgoingPhase phase;
  final DateTime startedAt;
  final DateTime? endsAt;

  /// It rings without sound because it is on silent there.
  final bool muted;

  bool get isActive => phase.isActive;

  OutgoingRing copyWith({
    OutgoingPhase? phase,
    DateTime? endsAt,
    bool? muted,
  }) => OutgoingRing(
    deviceId: deviceId,
    deviceName: deviceName,
    phase: phase ?? this.phase,
    startedAt: startedAt,
    endsAt: endsAt ?? this.endsAt,
    muted: muted ?? this.muted,
  );
}
