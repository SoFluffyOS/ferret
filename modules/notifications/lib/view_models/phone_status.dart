import 'package:protocol/notifications.dart';

/// A connected phone that mirrors its notifications here, as a computer sees
/// it.
class PhoneStatus {
  const PhoneStatus({
    required this.deviceId,
    required this.name,
    required this.settings,
    required this.unreachable,
  });

  final String deviceId;
  final String name;

  /// Null until the phone answered.
  final MirrorSettings? settings;

  /// The phone didn't answer the last time it was asked.
  final bool unreachable;

  /// Mirroring is on and Android lets Ferret read notifications.
  bool get isMirroring => switch (settings) {
    final MirrorSettings current => current.enabled && current.accessGranted,
    null => false,
  };
}
