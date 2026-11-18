import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Who this receiver is to iPhones: the MAC-like id AirPlay names a device
/// by, and the seed of the Ed25519 key it signs pair-verify with. Both
/// must stay the same between runs, or phones see a new receiver each time.
class AirPlayIdentity {
  AirPlayIdentity({required this.deviceId, required this.signingSeed}) {
    if (deviceId.length != 6) {
      throw ArgumentError.value(deviceId, 'deviceId', 'Must be 6 bytes');
    }

    if (signingSeed.length != 32) {
      throw ArgumentError.value(signingSeed, 'signingSeed', 'Must be 32 bytes');
    }
  }

  /// Derives both from [secret], which only this device may know, such as
  /// bytes derived from the app's own private identity key. The same
  /// secret always gives the same identity.
  factory AirPlayIdentity.derive(List<int> secret) {
    final idHash = sha256.convert([
      ...utf8.encode('ferret-airplay-device-id'),
      ...secret,
    ]).bytes;
    final seedHash = sha256.convert([
      ...utf8.encode('ferret-airplay-signing-seed'),
      ...secret,
    ]).bytes;
    final deviceId = Uint8List.fromList(idHash.sublist(0, 6));
    // Locally administered, one device: never a real card's address.
    deviceId[0] = (deviceId[0] | 0x02) & 0xfe;

    return AirPlayIdentity(
      deviceId: deviceId,
      signingSeed: Uint8List.fromList(seedHash),
    );
  }

  final Uint8List deviceId;
  final Uint8List signingSeed;

  /// `aa:bb:cc:dd:ee:ff`, as the `deviceid` TXT record and `/info` want it.
  String get deviceIdColons => _hex(deviceId).join(':');

  /// `AABBCCDDEEFF`, the start of the `_raop._tcp` instance name.
  String get deviceIdCompact => _hex(deviceId).join().toUpperCase();

  List<String> _hex(Uint8List bytes) => [
    for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
  ];
}
