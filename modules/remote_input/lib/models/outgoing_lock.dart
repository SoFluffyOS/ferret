import 'package:protocol/remote_input.dart';

/// This phone asked a computer to lock its screen: waiting, or how it went.
class OutgoingLock {
  const OutgoingLock({
    required this.deviceId,
    required this.deviceName,
    required this.at,
    this.result,
  });

  final String deviceId;
  final String deviceName;

  /// When it was asked, or answered once [result] is in.
  final DateTime at;

  /// Null while the computer hasn't answered, such as while it asks its
  /// owner.
  final LockResult? result;

  bool get isWaiting => result == null;
}
