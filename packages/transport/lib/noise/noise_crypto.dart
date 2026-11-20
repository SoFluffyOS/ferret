import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:transport/noise/chacha_poly.dart';

/// The primitives of `Noise_XX_25519_ChaChaPoly_SHA256`.
abstract final class NoiseCrypto {
  static const hashLength = 32;
  static const keyLength = 32;
  static const tagLength = 16;
  static const dhLength = 32;

  static final _x25519 = X25519();
  static final _sha256 = Sha256();
  static final _hmac = Hmac.sha256();

  static Future<SimpleKeyPair> generateKeyPair() => _x25519.newKeyPair();

  /// A key pair from a 32-byte X25519 private key.
  static Future<SimpleKeyPair> keyPairFromPrivateKey(List<int> privateKey) =>
      _x25519.newKeyPairFromSeed(privateKey);

  static Future<Uint8List> publicKeyOf(SimpleKeyPair keyPair) async {
    final publicKey = await keyPair.extractPublicKey();
    return Uint8List.fromList(publicKey.bytes);
  }

  static Future<Uint8List> privateKeyOf(SimpleKeyPair keyPair) async =>
      Uint8List.fromList(await keyPair.extractPrivateKeyBytes());

  static Future<Uint8List> dh(
    SimpleKeyPair keyPair,
    List<int> remotePublicKey,
  ) async {
    final remote = SimplePublicKey(remotePublicKey, type: .x25519);
    final shared = await _x25519.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: remote,
    );
    return Uint8List.fromList(await shared.extractBytes());
  }

  static Future<Uint8List> hash(List<int> data) async {
    final digest = await _sha256.hash(data);
    return Uint8List.fromList(digest.bytes);
  }

  static Future<Uint8List> hmac(List<int> key, List<int> data) async {
    final mac = await _hmac.calculateMac(data, secretKey: SecretKey(key));
    return Uint8List.fromList(mac.bytes);
  }

  /// Noise's HKDF: two or three outputs of [hashLength] bytes.
  static Future<List<Uint8List>> hkdf(
    List<int> chainingKey,
    List<int> inputKeyMaterial,
    int outputs,
  ) async {
    final tempKey = await hmac(chainingKey, inputKeyMaterial);
    final first = await hmac(tempKey, [1]);
    final second = await hmac(tempKey, [...first, 2]);
    if (outputs == 2) {
      return [first, second];
    }

    final third = await hmac(tempKey, [...second, 3]);
    return [first, second, third];
  }

  static Future<Uint8List> encrypt(
    List<int> key,
    int nonce,
    List<int> associatedData,
    List<int> plaintext,
  ) async =>
      ChaChaPoly.encrypt(key, _nonceBytes(nonce), associatedData, plaintext);

  /// Throws [SecretBoxAuthenticationError] when the message was tampered with.
  static Future<Uint8List> decrypt(
    List<int> key,
    int nonce,
    List<int> associatedData,
    List<int> ciphertext,
  ) async {
    final plaintext = ChaChaPoly.decrypt(
      key,
      _nonceBytes(nonce),
      associatedData,
      ciphertext,
    );
    if (plaintext == null) {
      throw SecretBoxAuthenticationError();
    }

    return plaintext;
  }

  static Uint8List _nonceBytes(int nonce) {
    final bytes = ByteData(12)..setUint64(4, nonce, Endian.little);
    return bytes.buffer.asUint8List();
  }
}
