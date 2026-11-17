import 'dart:convert';
import 'dart:typed_data';

import 'package:transport/noise/cipher_state.dart';
import 'package:transport/noise/noise_crypto.dart';

/// Noise's SymmetricState: the chaining key, the handshake hash and the
/// handshake's cipher.
class SymmetricState {
  SymmetricState._(this._chainingKey, this._hash);

  static Future<SymmetricState> initialize(String protocolName) async {
    final name = utf8.encode(protocolName);
    final hash = switch (name.length <= NoiseCrypto.hashLength) {
      true => Uint8List(NoiseCrypto.hashLength)..setAll(0, name),
      false => await NoiseCrypto.hash(name),
    };
    return SymmetricState._(Uint8List.fromList(hash), hash);
  }

  Uint8List _chainingKey;
  Uint8List _hash;
  final NoiseCipherState _cipher = NoiseCipherState();

  Uint8List get handshakeHash => Uint8List.fromList(_hash);

  Future<void> mixKey(List<int> inputKeyMaterial) async {
    final [chainingKey, tempKey] = await NoiseCrypto.hkdf(
      _chainingKey,
      inputKeyMaterial,
      2,
    );
    _chainingKey = chainingKey;
    _cipher.initializeKey(tempKey);
  }

  Future<void> mixHash(List<int> data) async {
    _hash = await NoiseCrypto.hash([..._hash, ...data]);
  }

  Future<Uint8List> encryptAndHash(List<int> plaintext) async {
    final ciphertext = await _cipher.encryptWithAd(_hash, plaintext);
    await mixHash(ciphertext);
    return ciphertext;
  }

  Future<Uint8List> decryptAndHash(List<int> ciphertext) async {
    final plaintext = await _cipher.decryptWithAd(_hash, ciphertext);
    await mixHash(ciphertext);
    return plaintext;
  }

  /// The two transport ciphers: initiator to responder, then responder to
  /// initiator.
  Future<(NoiseCipherState, NoiseCipherState)> split() async {
    final [first, second] = await NoiseCrypto.hkdf(_chainingKey, const [], 2);
    final initiatorToResponder = NoiseCipherState()..initializeKey(first);
    final responderToInitiator = NoiseCipherState()..initializeKey(second);
    return (initiatorToResponder, responderToInitiator);
  }
}
