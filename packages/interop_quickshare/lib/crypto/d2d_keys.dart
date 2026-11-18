import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:interop_quickshare/crypto/hkdf.dart';

/// The four keys that protect frames after the handshake: one pair to
/// encrypt and sign what this side sends, one to verify and decrypt what
/// it receives.
class D2DKeys {
  const D2DKeys({
    required this.encryptKey,
    required this.signKey,
    required this.decryptKey,
    required this.verifyKey,
  });

  /// Derives the keys from UKEY2's next protocol secret. The receiver of
  /// a transfer is the server.
  factory D2DKeys.derive(List<int> nextSecret, {required bool isServer}) {
    final clientKey = Hkdf.derive(
      key: nextSecret,
      salt: _d2dSalt,
      info: utf8.encode('client'),
    );
    final serverKey = Hkdf.derive(
      key: nextSecret,
      salt: _d2dSalt,
      info: utf8.encode('server'),
    );
    final (outgoing, incoming) = switch (isServer) {
      true => (serverKey, clientKey),
      false => (clientKey, serverKey),
    };

    return D2DKeys(
      encryptKey: _messageKey(outgoing, 'ENC:2'),
      signKey: _messageKey(outgoing, 'SIG:1'),
      decryptKey: _messageKey(incoming, 'ENC:2'),
      verifyKey: _messageKey(incoming, 'SIG:1'),
    );
  }

  static final List<int> _d2dSalt = sha256.convert(utf8.encode('D2D')).bytes;
  static final List<int> _messageSalt = sha256
      .convert(utf8.encode('SecureMessage'))
      .bytes;

  final Uint8List encryptKey;
  final Uint8List signKey;
  final Uint8List decryptKey;
  final Uint8List verifyKey;

  static Uint8List _messageKey(List<int> key, String purpose) =>
      Hkdf.derive(key: key, salt: _messageSalt, info: utf8.encode(purpose));
}
