import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:cryptography/cryptography.dart';
import 'package:transport/transport.dart';

/// This device's long-term X25519 key pair and the id derived from it.
class DeviceIdentity {
  const DeviceIdentity._(this.keyPair, this.publicKey, this.deviceId);

  static const _storageKey = 'ferret.identity';

  /// Loads the identity from [store], creating and saving one on first run.
  static Future<DeviceIdentity> loadOrCreate(SecretStore store) async {
    if (await store.read(_storageKey) case final saved?) {
      return fromPrivateKey(base64Decode(saved));
    }

    final keyPair = await NoiseCrypto.generateKeyPair();
    final privateKey = await NoiseCrypto.privateKeyOf(keyPair);
    await store.write(_storageKey, base64Encode(privateKey));
    return _fromKeyPair(keyPair);
  }

  static Future<DeviceIdentity> fromPrivateKey(List<int> privateKey) async =>
      _fromKeyPair(await NoiseCrypto.keyPairFromPrivateKey(privateKey));

  static Future<DeviceIdentity> generate() async =>
      _fromKeyPair(await NoiseCrypto.generateKeyPair());

  static Future<DeviceIdentity> _fromKeyPair(SimpleKeyPair keyPair) async {
    final publicKey = await NoiseCrypto.publicKeyOf(keyPair);
    return DeviceIdentity._(keyPair, publicKey, await deviceIdFor(publicKey));
  }

  final SimpleKeyPair keyPair;
  final Uint8List publicKey;

  /// 16 lowercase base32 characters, from the SHA-256 of [publicKey].
  final String deviceId;

  /// The device id of whoever holds [publicKey].
  static Future<String> deviceIdFor(List<int> publicKey) async {
    final digest = await NoiseCrypto.hash(publicKey);
    return _base32(digest.sublist(0, 10));
  }

  /// [deviceId] in groups of four, for showing to people.
  static String format(String deviceId) {
    final groups = [
      for (var i = 0; i < deviceId.length; i += 4)
        deviceId.substring(i, (i + 4).clamp(0, deviceId.length)),
    ];
    return groups.join('-');
  }

  static String _base32(List<int> bytes) {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz234567';
    final out = StringBuffer();
    var buffer = 0;
    var bits = 0;
    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.write(alphabet[(buffer >> bits) & 31]);
      }
    }

    if (bits > 0) {
      out.write(alphabet[(buffer << (5 - bits)) & 31]);
    }

    return out.toString();
  }
}
