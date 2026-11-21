import 'package:engine/trust/trust.dart';

/// Another of the user's devices wants to change who belongs to them here:
/// add a device it paired, or remove one it removed everywhere. Nothing
/// changes on this device until its user answers.
sealed class GroupRequest {
  const GroupRequest({
    required this.device,
    required this.introducer,
    required this.askedAt,
    required this.expiresAt,
  });

  /// The device to add or remove.
  final TrustedDevice device;

  /// The paired device that asks.
  final TrustedDevice introducer;

  final DateTime askedAt;

  /// When the request answers itself: an addition is turned down, a
  /// removal leaves the device where it is.
  final DateTime expiresAt;
}

/// [introducer] paired [device] and wants it among this device's devices.
/// It isn't trusted here yet.
final class JoinRequest extends GroupRequest {
  const JoinRequest({
    required super.device,
    required super.introducer,
    required super.askedAt,
    required super.expiresAt,
  });
}

/// [introducer] removed [device] from all the user's devices and wants it
/// gone here too. It stays trusted until the user says yes.
final class RemovalRequest extends GroupRequest {
  const RemovalRequest({
    required super.device,
    required super.introducer,
    required super.askedAt,
    required super.expiresAt,
    required this.forgottenAt,
  });

  /// When the user removed it on [introducer].
  final DateTime forgottenAt;
}
