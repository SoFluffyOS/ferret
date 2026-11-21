import 'dart:io';

/// Whether this app may send and receive multicast.
///
/// iOS refuses multicast and broadcast from an app without Apple's
/// `com.apple.developer.networking.multicast` entitlement, and each try
/// only fails. Once Apple grants it and the entitlement is in the iPhone
/// build, set [iosGranted] to true: everything that checks [allowed]
/// starts using multicast there.
abstract final class MulticastEntitlement {
  /// The one switch for the iPhone build.
  static const iosGranted = false;

  /// Multicast works here: everywhere but an iPhone without the
  /// entitlement.
  static bool get allowed => allowedOn(isIos: Platform.isIOS);

  static bool allowedOn({required bool isIos}) => !isIos || iosGranted;
}
