import 'dart:math';
import 'dart:typed_data';

import 'package:interop_localsend/security/der.dart';
import 'package:pointycastle/export.dart';

/// A certificate and its private key, both DER.
typedef CertificateAndKey = ({Uint8List certificate, Uint8List privateKey});

/// Makes the self-signed RSA certificate LocalSend members identify with.
///
/// The certificate is X.509 v3, RSA 2048 with SHA-256, like the ones the
/// LocalSend apps make, so every TLS stack they use accepts it. Nobody
/// checks its name or dates: members compare its SHA-256 instead.
abstract final class CertificateBuilder {
  static const _rsaEncryption = '1.2.840.113549.1.1.1';
  static const _sha256WithRsa = '1.2.840.113549.1.1.11';
  static const _commonName = '2.5.4.3';
  static const _basicConstraints = '2.5.29.19';
  static const _sha256DigestInfo = '0609608648016503040201';
  static const _keyBits = 2048;
  static const _validity = Duration(days: 3650);

  /// Generates a key pair and signs a certificate for it. Slow (a second
  /// or more): run it off the UI isolate.
  static CertificateAndKey selfSigned({
    required String commonName,
    DateTime? now,
  }) {
    final random = _secureRandom();
    final generator = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.from(65537), _keyBits, 64),
          random,
        ),
      );
    final pair = generator.generateKeyPair();
    final (publicKey, privateKey) = (pair.publicKey, pair.privateKey);
    final (modulus, exponent, privateExponent, p, q) = switch ((
      publicKey.modulus,
      publicKey.publicExponent,
      privateKey.privateExponent,
      privateKey.p,
      privateKey.q,
    )) {
      (
        final modulus?,
        final exponent?,
        final privateExponent?,
        final p?,
        final q?,
      ) =>
        (modulus, exponent, privateExponent, p, q),
      _ => throw StateError('RSA key generation returned an incomplete key'),
    };

    final start = (now ?? DateTime.now()).subtract(const Duration(days: 1));
    final algorithm = Der.sequence([Der.oid(_sha256WithRsa), Der.nullValue()]);
    final name = Der.sequence([
      Der.set([
        Der.sequence([Der.oid(_commonName), Der.utf8String(commonName)]),
      ]),
    ]);
    final publicKeyInfo = Der.sequence([
      Der.sequence([Der.oid(_rsaEncryption), Der.nullValue()]),
      Der.bitString(
        Der.sequence([Der.integer(modulus), Der.integer(exponent)]),
      ),
    ]);
    final extensions = Der.explicit(
      3,
      Der.sequence([
        Der.sequence([
          Der.oid(_basicConstraints),
          Der.octetString(Der.sequence(const [])),
        ]),
      ]),
    );
    final body = Der.sequence([
      Der.explicit(0, Der.integer(BigInt.two)),
      Der.integer(_serial(random)),
      algorithm,
      name,
      Der.sequence([Der.time(start), Der.time(start.add(_validity))]),
      name,
      publicKeyInfo,
      extensions,
    ]);

    final signer = RSASigner(SHA256Digest(), _sha256DigestInfo)
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final signature = signer.generateSignature(body).bytes;
    final certificate = Der.sequence([
      body,
      algorithm,
      Der.bitString(signature),
    ]);

    final pkcs1 = Der.sequence([
      Der.integer(BigInt.zero),
      Der.integer(modulus),
      Der.integer(exponent),
      Der.integer(privateExponent),
      Der.integer(p),
      Der.integer(q),
      Der.integer(privateExponent % (p - BigInt.one)),
      Der.integer(privateExponent % (q - BigInt.one)),
      Der.integer(q.modInverse(p)),
    ]);
    final pkcs8 = Der.sequence([
      Der.integer(BigInt.zero),
      Der.sequence([Der.oid(_rsaEncryption), Der.nullValue()]),
      Der.octetString(pkcs1),
    ]);

    return (certificate: certificate, privateKey: pkcs8);
  }

  static SecureRandom _secureRandom() {
    final source = Random.secure();
    final seed = Uint8List.fromList([
      for (var index = 0; index < 32; index++) source.nextInt(256),
    ]);
    return FortunaRandom()..seed(KeyParameter(seed));
  }

  /// A positive 63-bit serial number.
  static BigInt _serial(SecureRandom random) {
    final bytes = random.nextBytes(8);
    bytes[0] = (bytes[0] & 0x7f) | 0x01;
    return bytes.fold(
      BigInt.zero,
      (value, byte) => (value << 8) | BigInt.from(byte),
    );
  }
}
