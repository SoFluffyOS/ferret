import 'package:protocol/find.dart';

/// Where ringing this device stands.
enum LocalRingPhase { idle, ringing, stopped }

/// This device ringing because another one asked.
class LocalRing {
  const LocalRing({
    required this.phase,
    this.requesterIds = const [],
    this.requesterName = '',
    this.startedAt,
    this.endsAt,
    this.muted = false,
    this.reason = StopReason.STOP_REASON_UNSPECIFIED,
  });

  static const idle = LocalRing(phase: .idle);

  final LocalRingPhase phase;

  /// Devices that asked, which hear when it stops.
  final List<String> requesterIds;

  /// The last device that asked, for the "is looking for" line.
  final String requesterName;
  final DateTime? startedAt;
  final DateTime? endsAt;

  /// It rings without sound: on silent, and ringing on silent is off.
  final bool muted;

  /// Why it stopped, once [phase] is stopped.
  final StopReason reason;

  bool get isRinging => phase == .ringing;

  LocalRing copyWith({
    LocalRingPhase? phase,
    List<String>? requesterIds,
    String? requesterName,
    DateTime? endsAt,
    StopReason? reason,
  }) => LocalRing(
    phase: phase ?? this.phase,
    requesterIds: requesterIds ?? this.requesterIds,
    requesterName: requesterName ?? this.requesterName,
    startedAt: startedAt,
    endsAt: endsAt ?? this.endsAt,
    muted: muted,
    reason: reason ?? this.reason,
  );
}
