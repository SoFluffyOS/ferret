import 'package:engine/session/session.dart';
import 'package:engine/trust/trust.dart';

/// A paired device and its live session, if it is connected.
class DeviceStatus {
  const DeviceStatus(this.device, this.session);

  final TrustedDevice device;
  final Session? session;

  bool get isConnected => session != null;
}
