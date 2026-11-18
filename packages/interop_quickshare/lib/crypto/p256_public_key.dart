import 'dart:typed_data';

import 'package:interop_quickshare/proto/proto.dart';
import 'package:pointycastle/export.dart';

/// A point on P-256, as UKEY2 sends it: a `GenericPublicKey` with both
/// coordinates in big-endian two's complement.
class P256PublicKey {
  const P256PublicKey(this.x, this.y);

  static final domain = ECCurve_secp256r1();
  static const _maxCoordinateBytes = 33;

  /// The field prime of P-256: 2^256 - 2^224 + 2^192 + 2^96 - 1.
  static final _prime = BigInt.parse(
    'ffffffff00000001000000000000000000000000ffffffffffffffffffffffff',
    radix: 16,
  );

  final BigInt x;
  final BigInt y;

  /// Reads a serialized `GenericPublicKey`. Returns null unless it holds
  /// a valid point: a key off the curve would leak bits of the secret.
  static P256PublicKey? decode(List<int> bytes) {
    final GenericPublicKey key;
    try {
      key = GenericPublicKey.fromBuffer(bytes);
    } on Object {
      return null;
    }

    final point = key.ecP256PublicKey;
    if (key.type != PublicKeyType.EC_P256 ||
        point.x.isEmpty ||
        point.y.isEmpty ||
        point.x.length > _maxCoordinateBytes ||
        point.y.length > _maxCoordinateBytes) {
      return null;
    }

    final decoded = P256PublicKey(_unsigned(point.x), _unsigned(point.y));
    if (!decoded.isOnCurve) {
      return null;
    }

    return decoded;
  }

  /// Whether the point satisfies the curve equation y² = x³ + ax + b.
  bool get isOnCurve {
    final (a, b) = (
      domain.curve.a?.toBigInteger(),
      domain.curve.b?.toBigInteger(),
    );
    if (a == null || b == null) {
      return false;
    }

    if (x.isNegative || y.isNegative || x >= _prime || y >= _prime) {
      return false;
    }

    final left = (y * y) % _prime;
    final right = (x * x * x + a * x + b) % _prime;
    return left == right;
  }

  ECPoint get point => domain.curve.createPoint(x, y);

  /// The serialized `GenericPublicKey`.
  Uint8List encode() => GenericPublicKey(
    type: PublicKeyType.EC_P256,
    ecP256PublicKey: EcP256PublicKey(x: _signed(x), y: _signed(y)),
  ).writeToBuffer();

  static BigInt _unsigned(List<int> bytes) {
    var value = BigInt.zero;
    for (final byte in bytes) {
      value = (value << 8) | BigInt.from(byte);
    }

    return value;
  }

  /// The shortest two's complement form of a positive [value]: a zero
  /// byte in front when the top bit would read as a sign.
  static Uint8List _signed(BigInt value) {
    final length = value.bitLength ~/ 8 + 1;
    final bytes = Uint8List(length);
    var rest = value;
    for (var index = length - 1; index >= 0; index--) {
      bytes[index] = (rest & BigInt.from(0xff)).toInt();
      rest >>= 8;
    }

    return bytes;
  }
}
