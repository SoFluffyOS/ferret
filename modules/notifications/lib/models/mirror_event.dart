import 'package:notifications/models/mirrored_notification.dart';
import 'package:protocol/notifications.dart';

/// What a receiving device learns from a phone that mirrors notifications.
sealed class MirrorEvent {
  const MirrorEvent(this.deviceId);

  final String deviceId;
}

/// A new or updated notification.
final class MirrorPosted extends MirrorEvent {
  const MirrorPosted(super.deviceId, this.notification);

  final MirroredNotification notification;
}

final class MirrorRemoved extends MirrorEvent {
  const MirrorRemoved(super.deviceId, this.key);

  final String key;
}

/// The phone reconnected: [missedCount] notifications came while away, and
/// only [activeKeys] of the ones sent before are still showing.
final class MirrorCaughtUp extends MirrorEvent {
  const MirrorCaughtUp(
    super.deviceId, {
    required this.missedCount,
    required this.activeKeys,
    required this.missedAppNames,
  });

  final int missedCount;
  final Set<String> activeKeys;
  final List<String> missedAppNames;
}

/// The phone's mirroring settings changed, or were read for the first time
/// in this session.
final class MirrorSettingsChanged extends MirrorEvent {
  const MirrorSettingsChanged(super.deviceId, this.settings);

  final MirrorSettings settings;
}

/// The phone is connected but didn't answer when asked for its settings.
final class MirrorSettingsUnavailable extends MirrorEvent {
  const MirrorSettingsUnavailable(super.deviceId);
}

/// The phone disconnected or stopped answering.
final class MirrorSourceGone extends MirrorEvent {
  const MirrorSourceGone(super.deviceId);
}
