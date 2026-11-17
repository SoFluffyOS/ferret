import 'dart:typed_data';

import 'package:transport/noise/noise_crypto.dart';

/// Noise's CipherState: a key and a counting nonce.
class NoiseCipherState {
  /// Nonces stop one short of 2^64 - 1, as the spec reserves the last one.
  /// Dart's int is signed, so the counter tops out at 2^63 - 1 instead, which
  /// no session will ever reach.
  static const _maxNonce = 0x7fffffffffffffff;

  Uint8List? _key;
  int _nonce = 0;

  bool get hasKey => _key != null;

  void initializeKey(List<int>? key) {
    _key = switch (key) {
      final key? => Uint8List.fromList(key),
      null => null,
    };
    _nonce = 0;
  }

  Future<Uint8List> encryptWithAd(
    List<int> associatedData,
    List<int> plaintext,
  ) async {
    final key = _key;
    if (key == null) {
      return Uint8List.fromList(plaintext);
    }

    _checkNonce();
    final ciphertext = await NoiseCrypto.encrypt(
      key,
      _nonce,
      associatedData,
      plaintext,
    );
    _nonce++;
    return ciphertext;
  }

  Future<Uint8List> decryptWithAd(
    List<int> associatedData,
    List<int> ciphertext,
  ) async {
    final key = _key;
    if (key == null) {
      return Uint8List.fromList(ciphertext);
    }

    _checkNonce();
    final plaintext = await NoiseCrypto.decrypt(
      key,
      _nonce,
      associatedData,
      ciphertext,
    );
    _nonce++;
    return plaintext;
  }

  void _checkNonce() {
    if (_nonce >= _maxNonce) {
      throw StateError(
        'Noise nonce exhausted; the session must be rekeyed or closed.',
      );
    }
  }
}
