import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:interop_quickshare/crypto/p256_key_pair.dart';
import 'package:interop_quickshare/crypto/p256_public_key.dart';
import 'package:interop_quickshare/crypto/secure_bytes.dart';
import 'package:interop_quickshare/crypto/ukey2_constants.dart';
import 'package:interop_quickshare/crypto/ukey2_exception.dart';
import 'package:interop_quickshare/crypto/ukey2_keys.dart';
import 'package:interop_quickshare/proto/proto.dart';

/// The receiving side of one UKEY2 handshake: answer the client's init
/// with [serverInit], then complete with [finish].
class Ukey2Server {
  Ukey2Server({Random? random})
    : _random = random,
      _keyPair = P256KeyPair.generate(random);

  final Random? _random;
  final P256KeyPair _keyPair;
  Uint8List? _clientInit;
  Uint8List? _serverInit;
  List<int>? _commitment;

  /// Checks the client's first frame and returns the frame to answer
  /// with. Throws a [Ukey2Exception] when the client asks for something
  /// this side doesn't speak.
  Uint8List serverInit(Uint8List clientInitFrame) {
    final init = _parseClientInit(clientInitFrame);
    if (init.version != Ukey2Constants.version) {
      throw const Ukey2Exception('Version', alert: .BAD_VERSION);
    }

    if (init.random.length != Ukey2Constants.randomLength) {
      throw const Ukey2Exception('Random', alert: .BAD_RANDOM);
    }

    final commitment = _p256Commitment(init);
    if (commitment == null) {
      throw const Ukey2Exception('Cipher', alert: .BAD_HANDSHAKE_CIPHER);
    }

    if (init.nextProtocol != Ukey2Constants.nextProtocol) {
      throw const Ukey2Exception('Next protocol', alert: .BAD_NEXT_PROTOCOL);
    }

    final frame = Ukey2Message(
      messageType: .SERVER_INIT,
      messageData: Ukey2ServerInit(
        version: Ukey2Constants.version,
        random: SecureBytes.random(Ukey2Constants.randomLength, _random),
        handshakeCipher: .P256_SHA512,
        publicKey: _keyPair.publicKey.encode(),
      ).writeToBuffer(),
    ).writeToBuffer();
    _clientInit = clientInitFrame;
    _serverInit = frame;
    _commitment = commitment;
    return frame;
  }

  /// Checks the client's last frame against what it committed to and
  /// derives the keys. A mismatch closes without an alert, as UKEY2 asks.
  Ukey2Keys finish(Uint8List clientFinishFrame) {
    final (clientInit, serverInit, commitment) = (
      _clientInit,
      _serverInit,
      _commitment,
    );
    if (clientInit == null || serverInit == null || commitment == null) {
      throw const Ukey2Exception('Finish before init');
    }

    if (!SecureBytes.same(
      sha512.convert(clientFinishFrame).bytes,
      commitment,
    )) {
      throw const Ukey2Exception('Commitment mismatch');
    }

    final clientKey = _parseClientKey(clientFinishFrame);
    final sharedSecret = _keyPair.agree(clientKey);
    if (sharedSecret == null) {
      throw const Ukey2Exception('Key agreement');
    }

    return Ukey2Keys.derive(
      sharedSecret: sharedSecret,
      clientInit: clientInit,
      serverInit: serverInit,
    );
  }

  Ukey2ClientInit _parseClientInit(Uint8List frame) {
    final Ukey2Message message;
    try {
      message = Ukey2Message.fromBuffer(frame);
    } on Object {
      throw const Ukey2Exception('Unreadable message', alert: .BAD_MESSAGE);
    }

    if (message.messageType != Ukey2Message_Type.CLIENT_INIT) {
      throw const Ukey2Exception('Not an init', alert: .BAD_MESSAGE_TYPE);
    }

    try {
      return Ukey2ClientInit.fromBuffer(message.messageData);
    } on Object {
      throw const Ukey2Exception('Unreadable init', alert: .BAD_MESSAGE_DATA);
    }
  }

  List<int>? _p256Commitment(Ukey2ClientInit init) {
    for (final offered in init.cipherCommitments) {
      if (offered.handshakeCipher == Ukey2HandshakeCipher.P256_SHA512 &&
          offered.commitment.isNotEmpty) {
        return offered.commitment;
      }
    }

    return null;
  }

  P256PublicKey _parseClientKey(Uint8List frame) {
    final Ukey2ClientFinished finished;
    try {
      final message = Ukey2Message.fromBuffer(frame);
      if (message.messageType != Ukey2Message_Type.CLIENT_FINISH) {
        throw const Ukey2Exception('Not a finish');
      }

      finished = Ukey2ClientFinished.fromBuffer(message.messageData);
    } on Ukey2Exception {
      rethrow;
    } on Object {
      throw const Ukey2Exception('Unreadable finish');
    }

    final key = P256PublicKey.decode(finished.publicKey);
    if (key == null) {
      throw const Ukey2Exception('Client key');
    }

    return key;
  }
}
