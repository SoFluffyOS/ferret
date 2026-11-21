import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:transport/noise/cipher_state.dart';
import 'package:transport/noise/noise_crypto.dart';
import 'package:transport/noise/symmetric_state.dart';

/// The protocol Ferret speaks.
const noiseProtocolName = 'Noise_XX_25519_ChaChaPoly_SHA256';

/// Raised when a handshake message is malformed or fails authentication.
class NoiseHandshakeException implements Exception {
  const NoiseHandshakeException(this.message);

  final String message;

  @override
  String toString() => 'NoiseHandshakeException: $message';
}

/// The result of a finished handshake.
class NoiseHandshakeResult {
  const NoiseHandshakeResult({
    required this.send,
    required this.receive,
    required this.remoteStaticKey,
    required this.handshakeHash,
  });

  final NoiseCipherState send;
  final NoiseCipherState receive;

  /// The other side's X25519 static public key, which identifies the device.
  final Uint8List remoteStaticKey;

  /// Unique to this session; used for channel binding (pairing proofs and
  /// comparison codes).
  final Uint8List handshakeHash;
}

/// The XX handshake:
///
/// ```text
/// -> e
/// <- e, ee, s, es
/// -> s, se
/// ```
class NoiseXXHandshake {
  NoiseXXHandshake._({
    required this.initiator,
    required SimpleKeyPair staticKeyPair,
    required SymmetricState symmetric,
    SimpleKeyPair? ephemeralKeyPair,
  }) : _static = staticKeyPair,
       _symmetric = symmetric,
       _fixedEphemeral = ephemeralKeyPair;

  /// Starts a handshake. [ephemeralKeyPair] is only for test vectors.
  static Future<NoiseXXHandshake> create({
    required bool initiator,
    required SimpleKeyPair staticKeyPair,
    List<int> prologue = const [],
    SimpleKeyPair? ephemeralKeyPair,
  }) async {
    final symmetric = await SymmetricState.initialize(noiseProtocolName);
    await symmetric.mixHash(prologue);
    return NoiseXXHandshake._(
      initiator: initiator,
      staticKeyPair: staticKeyPair,
      symmetric: symmetric,
      ephemeralKeyPair: ephemeralKeyPair,
    );
  }

  final bool initiator;
  final SimpleKeyPair _static;
  final SymmetricState _symmetric;
  final SimpleKeyPair? _fixedEphemeral;

  SimpleKeyPair? _ephemeral;
  Uint8List? _remoteEphemeral;
  Uint8List? _remoteStatic;
  int _step = 0;

  bool get isFinished => _step == 3;

  /// The other side's static key, once its message carried it: after the
  /// second message for the initiator, before it shows its own.
  Uint8List? get remoteStatic => _remoteStatic;

  /// Whether this side writes the next handshake message.
  bool get isMyTurn => switch (initiator) {
    true => _step.isEven,
    false => _step.isOdd,
  };

  /// Writes the next handshake message, carrying [payload].
  Future<Uint8List> writeMessage([List<int> payload = const []]) async {
    if (!isMyTurn || isFinished) {
      throw StateError('Not this side\'s turn to write.');
    }

    final out = BytesBuilder(copy: false);
    switch (_step) {
      case 0:
        out.add(await _writeEphemeral());
      case 1:
        out.add(await _writeEphemeral());
        await _mixDh(_ephemeralKeyPair, _remoteEphemeralKey);
        out.add(
          await _symmetric.encryptAndHash(
            await NoiseCrypto.publicKeyOf(_static),
          ),
        );
        await _mixDh(_static, _remoteEphemeralKey);
      case 2:
        out.add(
          await _symmetric.encryptAndHash(
            await NoiseCrypto.publicKeyOf(_static),
          ),
        );
        await _mixDh(_static, _remoteEphemeralKey);
    }

    out.add(await _symmetric.encryptAndHash(payload));
    _step++;
    return out.takeBytes();
  }

  /// Reads the other side's next handshake message and returns its payload.
  Future<Uint8List> readMessage(List<int> message) async {
    if (isMyTurn || isFinished) {
      throw StateError('Not this side\'s turn to read.');
    }

    var offset = 0;
    List<int> take(int length) {
      if (message.length < offset + length) {
        throw const NoiseHandshakeException('Handshake message too short.');
      }

      final bytes = message.sublist(offset, offset + length);
      offset += length;
      return bytes;
    }

    const encryptedKeyLength = NoiseCrypto.dhLength + NoiseCrypto.tagLength;
    try {
      switch (_step) {
        case 0:
          await _readEphemeral(take(NoiseCrypto.dhLength));
        case 1:
          await _readEphemeral(take(NoiseCrypto.dhLength));
          await _mixDh(_ephemeralKeyPair, _remoteEphemeralKey);
          _remoteStatic = await _symmetric.decryptAndHash(
            take(encryptedKeyLength),
          );
          await _mixDh(_ephemeralKeyPair, _remoteStaticKey);
        case 2:
          _remoteStatic = await _symmetric.decryptAndHash(
            take(encryptedKeyLength),
          );
          await _mixDh(_ephemeralKeyPair, _remoteStaticKey);
      }

      final payload = await _symmetric.decryptAndHash(message.sublist(offset));
      _step++;
      return payload;
    } on SecretBoxAuthenticationError {
      throw const NoiseHandshakeException(
        'Handshake message failed authentication.',
      );
    }
  }

  /// The transport ciphers and the remote identity, once [isFinished].
  Future<NoiseHandshakeResult> finish() async {
    if (!isFinished) {
      throw StateError('Handshake is not finished.');
    }

    final (initiatorToResponder, responderToInitiator) = await _symmetric
        .split();
    final (send, receive) = switch (initiator) {
      true => (initiatorToResponder, responderToInitiator),
      false => (responderToInitiator, initiatorToResponder),
    };
    return NoiseHandshakeResult(
      send: send,
      receive: receive,
      remoteStaticKey: _remoteStaticKey,
      handshakeHash: _symmetric.handshakeHash,
    );
  }

  SimpleKeyPair get _ephemeralKeyPair => switch (_ephemeral) {
    final keyPair? => keyPair,
    null => throw StateError('No local ephemeral key yet.'),
  };

  Uint8List get _remoteEphemeralKey => switch (_remoteEphemeral) {
    final key? => key,
    null => throw StateError('No remote ephemeral key yet.'),
  };

  Uint8List get _remoteStaticKey => switch (_remoteStatic) {
    final key? => key,
    null => throw StateError('No remote static key yet.'),
  };

  Future<Uint8List> _writeEphemeral() async {
    final keyPair = _fixedEphemeral ?? await NoiseCrypto.generateKeyPair();
    _ephemeral = keyPair;

    final publicKey = await NoiseCrypto.publicKeyOf(keyPair);
    await _symmetric.mixHash(publicKey);
    return publicKey;
  }

  Future<void> _readEphemeral(List<int> publicKey) async {
    _remoteEphemeral = Uint8List.fromList(publicKey);
    await _symmetric.mixHash(publicKey);
  }

  /// In XX the initiator's `es` is DH(e, rs) and the responder's is DH(s, re),
  /// and `se` the other way round; each call site passes the right pair.
  Future<void> _mixDh(SimpleKeyPair keyPair, List<int> remotePublicKey) async {
    await _symmetric.mixKey(await NoiseCrypto.dh(keyPair, remotePublicKey));
  }
}
