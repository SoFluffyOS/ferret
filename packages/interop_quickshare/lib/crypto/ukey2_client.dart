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

/// The sending side of one UKEY2 handshake: send [clientInit], then
/// answer the server's init with [finish].
class Ukey2Client {
  Ukey2Client({Random? random})
    : _random = random,
      _keyPair = P256KeyPair.generate(random);

  final Random? _random;
  final P256KeyPair _keyPair;
  Uint8List? _clientInit;

  /// The last frame of the handshake. It is made first, because the
  /// first frame commits to its hash.
  late final Uint8List _clientFinish = Ukey2Message(
    messageType: .CLIENT_FINISH,
    messageData: Ukey2ClientFinished(
      publicKey: _keyPair.publicKey.encode(),
    ).writeToBuffer(),
  ).writeToBuffer();

  /// The first frame to send.
  Uint8List clientInit() => _clientInit ??= Ukey2Message(
    messageType: .CLIENT_INIT,
    messageData: Ukey2ClientInit(
      version: Ukey2Constants.version,
      random: SecureBytes.random(Ukey2Constants.randomLength, _random),
      cipherCommitments: [
        Ukey2ClientInit_CipherCommitment(
          handshakeCipher: .P256_SHA512,
          commitment: sha512.convert(_clientFinish).bytes,
        ),
      ],
      nextProtocol: Ukey2Constants.nextProtocol,
    ).writeToBuffer(),
  ).writeToBuffer();

  /// Checks the server's answer, and returns the last frame to send with
  /// the keys both sides now share.
  ({Uint8List clientFinish, Ukey2Keys keys}) finish(Uint8List serverInitFrame) {
    final clientInit = _clientInit;
    if (clientInit == null) {
      throw const Ukey2Exception('Finish before init');
    }

    final serverKey = _parseServerKey(serverInitFrame);
    final sharedSecret = _keyPair.agree(serverKey);
    if (sharedSecret == null) {
      throw const Ukey2Exception('Key agreement');
    }

    final keys = Ukey2Keys.derive(
      sharedSecret: sharedSecret,
      clientInit: clientInit,
      serverInit: serverInitFrame,
    );
    return (clientFinish: _clientFinish, keys: keys);
  }

  P256PublicKey _parseServerKey(Uint8List frame) {
    final Ukey2ServerInit init;
    try {
      final message = Ukey2Message.fromBuffer(frame);
      if (message.messageType != Ukey2Message_Type.SERVER_INIT) {
        throw const Ukey2Exception(
          'Not a server init',
          alert: .BAD_MESSAGE_TYPE,
        );
      }

      init = Ukey2ServerInit.fromBuffer(message.messageData);
    } on Ukey2Exception {
      rethrow;
    } on Object {
      throw const Ukey2Exception('Unreadable init', alert: .BAD_MESSAGE);
    }

    if (init.version != Ukey2Constants.version) {
      throw const Ukey2Exception('Version', alert: .BAD_VERSION);
    }

    if (init.random.length != Ukey2Constants.randomLength) {
      throw const Ukey2Exception('Random', alert: .BAD_RANDOM);
    }

    if (init.handshakeCipher != Ukey2HandshakeCipher.P256_SHA512) {
      throw const Ukey2Exception('Cipher', alert: .BAD_HANDSHAKE_CIPHER);
    }

    final key = P256PublicKey.decode(init.publicKey);
    if (key == null) {
      throw const Ukey2Exception('Server key', alert: .BAD_PUBLIC_KEY);
    }

    return key;
  }
}
