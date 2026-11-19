import 'package:engine/connection/version_mismatch.dart';
import 'package:engine/session/session.dart';
import 'package:engine/trust/trust.dart';

/// A paired device and its live session, if it is connected.
class DeviceStatus {
  const DeviceStatus(
    this.device,
    this.session, {
    this.isReconnecting = false,
    this.versionMismatch,
    this.reachedOverVpn = false,
  });

  final TrustedDevice device;
  final Session? session;

  /// The connection dropped without a goodbye a moment ago and Ferret is
  /// dialing it again, such as after the Wi-Fi hopped to another access
  /// point. It turns false once connected, or after about 45 seconds.
  final bool isReconnecting;

  /// It answered, but its Ferret and this one no longer speak the same
  /// protocol: one of them needs an update before they connect again.
  final VersionMismatch? versionMismatch;

  /// The session runs over the user's VPN rather than the local network,
  /// such as with a phone away from home. Large transfers may be slower.
  final bool reachedOverVpn;

  bool get isConnected => session != null;

  /// Connected over a slow link, such as far from the Wi-Fi.
  bool get isWeak => session?.isWeak ?? false;

  /// Connected, but nobody is at it: a computer that said its screen is
  /// locked or showing another account. What is sent there waits for the
  /// person to come back.
  bool get isAway => session?.remotePresence.away ?? false;
}
