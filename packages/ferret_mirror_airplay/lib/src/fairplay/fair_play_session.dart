import 'dart:typed_data';

import 'package:ferret_mirror_airplay/src/fairplay/fair_play_replies.dart';
import 'package:ferret_mirror_airplay/src/fairplay/playfair_bindings.dart';

/// Turns the phone's 72-byte encrypted key into the 16-byte AES key, given
/// the 164-byte FairPlay message. The real one is the vendored playfair C
/// code; tests pass their own.
typedef FairPlayDecrypt = Uint8List Function(
  Uint8List keyMessage,
  Uint8List encryptedKey,
);

/// One connection's FairPlay exchange (`/fp-setup`, version 3): two
/// requests, then the key of the SETUP request can be decrypted.
///
/// FairPlay is Apple's, reverse-engineered by the playfair project. Nothing
/// here is documented by Apple, and a new iOS can change it.
class FairPlaySession {
  FairPlaySession({FairPlayDecrypt decrypt = playfairDecrypt})
    : _decrypt = decrypt;

  static const setupLength = 16;
  static const handshakeLength = playfairMessageLength;
  static const encryptedKeyLength = playfairKeyLength;
  static const _version = 0x03;

  final FairPlayDecrypt _decrypt;
  Uint8List? _keyMessage;

  /// Answers either request, told apart by length. Null when the request
  /// isn't a FairPlay version 3 message this session understands.
  Uint8List? answer(Uint8List request) {
    if (request.length == setupLength) {
      return _setup(request);
    }

    if (request.length == handshakeLength) {
      return _handshake(request);
    }

    return null;
  }

  /// The AES key inside [encryptedKey], or null before the handshake.
  Uint8List? decryptKey(Uint8List encryptedKey) {
    final keyMessage = _keyMessage;
    if (keyMessage == null || encryptedKey.length != encryptedKeyLength) {
      return null;
    }

    return _decrypt(
      Uint8List.fromList(keyMessage),
      Uint8List.fromList(encryptedKey),
    );
  }

  Uint8List? _setup(Uint8List request) {
    final mode = request[14];
    if (request[4] != _version || mode >= FairPlayReplies.byMode.length) {
      return null;
    }

    _keyMessage = null;
    return Uint8List.fromList(FairPlayReplies.byMode[mode]);
  }

  Uint8List? _handshake(Uint8List request) {
    if (request[4] != _version ||
        request[playfairModeOffset] >= playfairModes) {
      return null;
    }

    _keyMessage = Uint8List.fromList(request);
    return Uint8List.fromList([
      ...FairPlayReplies.handshakeHeader,
      ...request.sublist(144, 164),
    ]);
  }
}
