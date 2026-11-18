/// Where this device's control of another one stands.
enum OutgoingPhase {
  requesting,

  /// The other device asks its owner.
  waitingForConsent,
  active,

  /// The other device said no; see [OutgoingControl.denial].
  denied,

  /// The other device ended it; see [OutgoingControl.stop].
  stopped,
  lostConnection,

  /// It isn't connected, or didn't answer.
  unreachable;

  bool get isLive => switch (this) {
    requesting || waitingForConsent || active => true,
    _ => false,
  };
}

/// Why the other device said no.
enum OutgoingDenial {
  denied,
  timeout,
  busy,
  needsPermission,
  unsupported,
  turnedOff,
  version,
}

/// Why the other device ended control.
enum OutgoingStop { stoppedOnHost, idle, revoked, failed }

/// This device controlling another, such as a phone used as a touchpad.
class OutgoingControl {
  const OutgoingControl({
    required this.deviceId,
    required this.deviceName,
    required this.phase,
    this.denial,
    this.stop,
    this.always = false,
  });

  final String deviceId;
  final String deviceName;
  final OutgoingPhase phase;
  final OutgoingDenial? denial;
  final OutgoingStop? stop;

  /// The other device allowed this one for good.
  final bool always;

  bool get isActive => phase == .active;

  OutgoingControl copyWith({
    OutgoingPhase? phase,
    OutgoingDenial? denial,
    OutgoingStop? stop,
    bool? always,
  }) => OutgoingControl(
    deviceId: deviceId,
    deviceName: deviceName,
    phase: phase ?? this.phase,
    denial: denial ?? this.denial,
    stop: stop ?? this.stop,
    always: always ?? this.always,
  );
}
