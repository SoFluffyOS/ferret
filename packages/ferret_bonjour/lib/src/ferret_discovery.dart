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

  static Discovery forPlatform({
    BonjourBackend backend = const BonsoirBackend(),
  }) {
    if (!usesBonjour) {
      return CombinedDiscovery.standard();
    }

    return CombinedDiscovery([
      MulticastDiscovery(),
      FallbackDiscovery(BonjourDiscovery(backend: backend), MdnsDiscovery()),
    ]);
  }
}
