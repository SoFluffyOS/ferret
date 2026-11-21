import 'dart:io';

import 'package:ferret_bonjour/src/bonjour_backend.dart';
import 'package:ferret_bonjour/src/bonjour_discovery.dart';
import 'package:ferret_bonjour/src/bonsoir_backend.dart';
import 'package:transport/transport.dart';

/// How Ferret looks for devices on this platform.
///
/// On macOS, iOS and Android the system's Bonjour offers and finds
/// `_ferret._tcp` next to Ferret's own multicast announce; Ferret's own
/// DNS-SD only steps in when Bonjour can't start, because both offering the
/// same name would clash. Windows and Linux keep Ferret's own two ways.
abstract final class FerretDiscovery {
  static bool get usesBonjour =>
      Platform.isMacOS || Platform.isIOS || Platform.isAndroid;

  /// Whether discovery waits for [HeldDiscovery.release]: on an iPhone the
  /// first packet makes iOS ask about the local network, so Ferret holds
  /// back until the person reached a place that looks for devices.
  static bool get holdsUntilAsked => Platform.isIOS;

  /// [released] lets a held discovery run from the start, such as once
  /// something is paired.
  static Discovery forPlatform({
    BonjourBackend backend = const BonsoirBackend(),
    bool released = false,
  }) {
    if (!usesBonjour) {
      return CombinedDiscovery.standard();
    }

    final discovery = CombinedDiscovery([
      MulticastDiscovery(),
      FallbackDiscovery(BonjourDiscovery(backend: backend), MdnsDiscovery()),
    ]);
    if (!holdsUntilAsked) {
      return discovery;
    }

    return HeldDiscovery(discovery, released: released);
  }
}
