import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:interop_quickshare/crypto/hkdf.dart';

/// What a finished UKEY2 handshake gives both sides.
class Ukey2Keys {
  const Ukey2Keys({required this.authString, required this.nextSecret});

  /// Derives both values from the P-256 [sharedSecret] and the exact
  /// bytes of the first two handshake messages.
  factory Ukey2Keys.derive({
    required List<int> sharedSecret,
    required List<int> clientInit,
    required List<int> serverInit,
  }) {
    final key = sha256.convert(sharedSecret).bytes;
    final transcript = [...clientInit, ...serverInit];
    return Ukey2Keys(
      authString: Hkdf.derive(
        key: key,
        salt: utf8.encode('UKEY2 v1 auth'),
        info: transcript,
      ),
      nextSecret: Hkdf.derive(
        key: key,
        salt: utf8.encode('UKEY2 v1 next'),
        info: transcript,
      ),
    );
  }

  /// Both sides show something made from this, so people can compare.
  /// Quick Share turns it into a 4-digit PIN.
  final Uint8List authString;

  /// The secret the frame keys are derived from.
  final Uint8List nextSecret;
}
