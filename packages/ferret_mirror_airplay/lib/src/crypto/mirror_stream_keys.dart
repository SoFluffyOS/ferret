import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Derives the AES-128-CTR key and IV of the mirroring video stream, the
/// way open source receivers (RPiPlay, UxPlay) do it.
abstract final class MirrorStreamKeys {
  static const _length = 16;

  /// The key the FairPlay step gave, hashed with the pair-verify secret.
  /// Without a secret (a phone that skipped pairing) the key stays as is.
  static Uint8List sessionKey(Uint8List fairPlayKey, Uint8List? sharedSecret) {
    if (sharedSecret == null) {
      return Uint8List.fromList(fairPlayKey);
    }

    return _first16(sha512.convert([...fairPlayKey, ...sharedSecret]));
  }

  /// The video stream's own key and IV: the session key hashed with a
  /// label and the stream connection id, written as an unsigned number.
  static ({Uint8List key, Uint8List iv}) forStream(
    Uint8List sessionKey,
    int streamConnectionId,
  ) {
    final id = BigInt.from(streamConnectionId).toUnsigned(64);
    return (
      key: _first16(
        sha512.convert([...utf8.encode('AirPlayStreamKey$id'), ...sessionKey]),
      ),
      iv: _first16(
        sha512.convert([...utf8.encode('AirPlayStreamIV$id'), ...sessionKey]),
      ),
    );
  }

  static Uint8List _first16(Digest digest) =>
      Uint8List.fromList(digest.bytes.sublist(0, _length));
}
