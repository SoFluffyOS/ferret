import 'package:find/models/models.dart';

/// How ringing a connected device is doing, from what it said last and how
/// the last ring went. A failed ring outranks older good news.
RingHealth ringHealthOf({
  required bool supported,
  RemoteRingInfo? remote,
  OutgoingRing? lastRing,
}) {
  if (!supported) {
    return .unsupported;
  }

  final lastFailure = switch (lastRing?.phase) {
    .unreachable || .lostConnection => RingHealth.notAnswering,
    .noSound => RingHealth.noSound,
    .notSupported => RingHealth.unsupported,
    _ => null,
  };
  if (lastFailure != null) {
    return lastFailure;
  }

  if (remote == null) {
    return .unknown;
  }

  final info = remote.info;
  if (info == null) {
    return .notAnswering;
  }

  if (info.needsPermission) {
    return .needsPermission;
  }

  if (info.needsAppOpen) {
    return .needsAppOpen;
  }

  if (info.ringsWhenSilent) {
    return .loud;
  }

  return .followsSilent;
}
