/// Where this computer stands with lending its desktop to another device.
enum ExtendPhase {
  /// The other device is asking its owner.
  asking,

  /// Its owner said yes; the display is being made.
  starting,

  /// The other device shows this computer's extra display.
  extending,
}

/// Why this computer's desktop isn't on another device (any more).
enum ExtendEnd {
  /// Its owner said no.
  declined,

  /// Nobody answered on it in time.
  timedOut,

  /// It is somebody's display already, or is asked to be.
  busy,

  /// It can't be a display, such as a Ferret too old for it.
  unsupported,

  notConnected,

  /// It didn't answer the offer.
  noAnswer,

  /// This computer can't make an extra display.
  cannotExtend,

  /// Screen Recording isn't allowed for Ferret here.
  needsScreenRecording,

  /// Stop on this computer.
  stoppedHere,

  /// Stop on the other device.
  stoppedThere,

  lostConnection,

  /// The system took the display away, or ended the capture.
  systemEnded,

  /// Making, capturing or encoding the display failed.
  failed,
}

/// One time this computer lent, or offered to lend, its desktop.
class ExtendSession {
  const ExtendSession({
    required this.deviceId,
    required this.deviceName,
    required this.phase,
    required this.askedAt,
    this.answerBy,
    this.startedAt,
  });

  final String deviceId;
  final String deviceName;
  final ExtendPhase phase;
  final DateTime askedAt;

  /// While [ExtendPhase.asking]: when the other device gives up asking.
  final DateTime? answerBy;

  /// When the display started showing there.
  final DateTime? startedAt;

  ExtendSession copyWith({
    ExtendPhase? phase,
    DateTime? answerBy,
    DateTime? startedAt,
  }) => ExtendSession(
    deviceId: deviceId,
    deviceName: deviceName,
    phase: phase ?? this.phase,
    askedAt: askedAt,
    answerBy: answerBy ?? this.answerBy,
    startedAt: startedAt ?? this.startedAt,
  );
}

/// How the last time ended, for its Activity line until dismissed.
class ExtendRecord {
  const ExtendRecord({
    required this.deviceId,
    required this.deviceName,
    required this.end,
    required this.at,
    this.startedAt,
  });

  final String deviceId;
  final String deviceName;
  final ExtendEnd end;
  final DateTime at;

  /// Set when the display was showing there before it ended.
  final DateTime? startedAt;
}
