import 'dart:math';
import 'dart:typed_data';

import 'package:interop_quickshare/crypto/p256_public_key.dart';
import 'package:interop_quickshare/crypto/secure_bytes.dart';

/// A P-256 key pair made for one handshake and thrown away after it.
class P256KeyPair {
  P256KeyPair._(this._secret, this.publicKey);

  /// Makes a new pair. [random] is for tests; the default is the system's
  /// secure source.
  factory P256KeyPair.generate([Random? random]) {
    while (true) {
      final pair = fromSecret(_toBigInt(SecureBytes.random(32, random)));
      if (pair != null) {
        return pair;
      }
    }
  }

  /// The pair that belongs to [secret], or null when it is no valid
  /// P-256 secret. For known-answer tests; real pairs come from
  /// [P256KeyPair.generate].
  static P256KeyPair? fromSecret(BigInt secret) {
    if (secret <= BigInt.zero || secret >= P256PublicKey.domain.n) {
      return null;
    }

    final point = P256PublicKey.domain.G * secret;
    final (x, y) = (point?.x?.toBigInteger(), point?.y?.toBigInteger());
    if (x == null || y == null) {
      return null;
    }

    return P256KeyPair._(secret, P256PublicKey(x, y));
  }

  final BigInt _secret;
  final P256PublicKey publicKey;

  /// The x coordinate of the point both sides arrive at, as 32 bytes, or
  /// null when [other] leads nowhere.
  Uint8List? agree(P256PublicKey other) {
    final shared = other.point * _secret;
    final x = shared?.x?.toBigInteger();
    if (shared == null || shared.isInfinity || x == null) {
      return null;
    }

    final bytes = Uint8List(32);
    var rest = x;
    for (var index = 31; index >= 0; index--) {
      bytes[index] = (rest & BigInt.from(0xff)).toInt();
      rest >>= 8;
    }

    return bytes;
  }

  static BigInt _toBigInt(List<int> bytes) {
    var value = BigInt.zero;
    for (final byte in bytes) {
      value = (value << 8) | BigInt.from(byte);
    }

    return value;
  }
}
