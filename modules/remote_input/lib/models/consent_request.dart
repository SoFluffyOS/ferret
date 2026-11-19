/// What a device asks this computer's owner for.
enum ConsentKind {
  /// To move the pointer and type.
  control,

  /// To lock the screen, once.
  lock,
}

/// A device waiting for this computer's owner to let it take control, or
/// lock the screen.
class ConsentRequest {
  const ConsentRequest({
    required this.deviceId,
    required this.deviceName,
    required this.askedAt,
    this.kind = .control,
  });

  final String deviceId;
  final String deviceName;
  final DateTime askedAt;
  final ConsentKind kind;
}
