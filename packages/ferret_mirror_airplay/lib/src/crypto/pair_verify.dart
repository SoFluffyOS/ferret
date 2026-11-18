import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:ferret_mirror_airplay/src/crypto/aes_ctr_stream.dart';

/// The receiver's side of AirPlay's legacy pair-verify, one per connection.
///
/// The phone sends an X25519 key and its Ed25519 key. Both sides derive a
/// shared secret, sign the two X25519 keys with their Ed25519 key and send
/// the signature encrypted with AES-CTR under keys hashed from the secret.
/// The secret later takes part in the video key.
class PairVerify {
  PairVerify({required this.signingSeed, List<int>? ephemeralSeed})
    : _ephemeralSeed = ephemeralSeed;

  static const keyLength = 32;
  static const signatureLength = 64;
  static const _keySalt = 'Pair-Verify-AES-Key';
  static const _ivSalt = 'Pair-Verify-AES-IV';

  static final _ed25519 = Ed25519();
  static final _x25519 = X25519();

  /// The seed of this receiver's long-lived Ed25519 key.
  final Uint8List signingSeed;

  /// Fixes the X25519 key instead of a random one. For tests only.
  final List<int>? _ephemeralSeed;

  Uint8List? _sharedSecret;
  Uint8List? _ourPublic;
  Uint8List? _theirPublic;
  Uint8List? _theirSigningKey;
  bool _verified = false;

  /// The X25519 secret, once the phone has sent its key.
  Uint8List? get sharedSecret => _sharedSecret;

  /// The phone proved it holds the Ed25519 key it sent.
  bool get isVerified => _verified;

  /// The public half of the key made from [signingSeed]: the `pk` phones
  /// see in the TXT records, `/info` and the pair-setup answer.
  static Future<Uint8List> publicKeyOf(Uint8List signingSeed) async {
    final keyPair = await _ed25519.newKeyPairFromSeed(signingSeed);
    final publicKey = await keyPair.extractPublicKey();
    return Uint8List.fromList(publicKey.bytes);
  }

  /// First step: takes the phone's X25519 and Ed25519 public keys and
  /// returns this side's X25519 public key followed by the encrypted
  /// signature, 96 bytes.
  Future<Uint8List> start(
    Uint8List theirPublic,
    Uint8List theirSigningKey,
  ) async {
    if (theirPublic.length != keyLength ||
        theirSigningKey.length != keyLength) {
      throw ArgumentError('Pair-verify keys must be $keyLength bytes each');
    }

    final seed = _ephemeralSeed;
    final keyPair = switch (seed) {
      null => await _x25519.newKeyPair(),
      _ => await _x25519.newKeyPairFromSeed(seed),
    };
    final ourPublic = Uint8List.fromList(
      (await keyPair.extractPublicKey()).bytes,
    );
    final secret = await _x25519.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(theirPublic, type: KeyPairType.x25519),
    );
    final sharedSecret = Uint8List.fromList(await secret.extractBytes());
    final signingKey = await _ed25519.newKeyPairFromSeed(signingSeed);
    final signature = await _ed25519.sign([
      ...ourPublic,
      ...theirPublic,
    ], keyPair: signingKey);

    _sharedSecret = sharedSecret;
    _ourPublic = ourPublic;
    _theirPublic = Uint8List.fromList(theirPublic);
    _theirSigningKey = Uint8List.fromList(theirSigningKey);
    _verified = false;

    final encrypted = _cipher(
      sharedSecret,
    ).process(Uint8List.fromList(signature.bytes));
    return Uint8List.fromList([...ourPublic, ...encrypted]);
  }

  /// Second step: checks the phone's encrypted signature over both X25519
  /// keys. False when it doesn't match, or when [start] didn't come first.
  Future<bool> finish(Uint8List encryptedSignature) async {
    final sharedSecret = _sharedSecret;
    final ourPublic = _ourPublic;
    final theirPublic = _theirPublic;
    final theirSigningKey = _theirSigningKey;
    if (sharedSecret == null ||
        ourPublic == null ||
        theirPublic == null ||
        theirSigningKey == null ||
        encryptedSignature.length != signatureLength) {
      return false;
    }

    // The phone's signature continues the key stream this side's own
    // signature started, so that first stretch is skipped.
    final cipher = _cipher(sharedSecret)..process(Uint8List(signatureLength));
    final signature = cipher.process(encryptedSignature);

    _verified = await _ed25519.verify(
      [...theirPublic, ...ourPublic],
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(theirSigningKey, type: KeyPairType.ed25519),
      ),
    );
    return _verified;
  }

  static AesCtrStream _cipher(Uint8List sharedSecret) => AesCtrStream(
    _derive(_keySalt, sharedSecret),
    _derive(_ivSalt, sharedSecret),
  );

  static Uint8List _derive(String salt, Uint8List sharedSecret) {
    final hash = hashes.sha512.convert([...utf8.encode(salt), ...sharedSecret]);
    return Uint8List.fromList(hash.bytes.sublist(0, 16));
  }
}
