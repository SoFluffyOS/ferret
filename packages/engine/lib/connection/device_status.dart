import 'package:engine/session/session.dart';
import 'package:engine/trust/trust.dart';

/// A paired device and its live session, if it is connected.
class DeviceStatus {
  const DeviceStatus(this.device, this.session, {this.isReconnecting = false});

  final TrustedDevice device;
  final Session? session;

  /// The connection dropped without a goodbye a moment ago and Ferret is
  /// dialing it again, such as after the Wi-Fi hopped to another access
  /// point. It turns false once connected, or after about 45 seconds.
  final bool isReconnecting;

  bool get isConnected => session != null;

  /// Connected over a slow link, such as far from the Wi-Fi.
  bool get isWeak => session?.isWeak ?? false;
}
