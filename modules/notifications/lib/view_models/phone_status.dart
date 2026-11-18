import 'package:notifications/view_models/phone_state.dart';
import 'package:protocol/notifications.dart';

/// A paired Android phone as a computer sees it: whether it is connected,
/// whether it mirrors here and with which settings.
class PhoneStatus {
  const PhoneStatus({
    required this.deviceId,
    required this.name,
    required this.settings,
    required this.unreachable,
    this.online = true,
    this.sends = true,
  });

  final String deviceId;
  final String name;

  /// Null until the phone answered.
  final MirrorSettings? settings;

  /// The phone didn't answer the last time it was asked.
  final bool unreachable;

  /// The phone is connected right now.
  final bool online;

  /// The phone's Ferret offers to send its notifications. An older or
  /// trimmed build may not.
  final bool sends;

  /// Mirroring is on and Android lets Ferret read notifications.
  bool get isMirroring => switch (settings) {
    final MirrorSettings current => current.enabled && current.accessGranted,
    null => false,
  };

  /// What keeps this phone's notifications from showing here.
  PhoneState get state => switch (this) {
    PhoneStatus(online: false) => .offline,
    PhoneStatus(sends: false) => .off,
    PhoneStatus(unreachable: true) => .unreachable,
    PhoneStatus(settings: null) => .checking,
    PhoneStatus(settings: final current?) when !current.enabled => .off,
    PhoneStatus(settings: final current?) when !current.accessGranted =>
      .accessOff,
    _ => .mirroring,
  };
}
