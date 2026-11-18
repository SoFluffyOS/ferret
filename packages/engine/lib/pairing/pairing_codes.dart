import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

/// Turns pairing offers into links and QR payloads, and computes the proofs
/// and comparison codes that bind a pairing to one Noise session.
abstract final class PairingCodes {
  static const scheme = 'ferret';
  static const secretLength = 16;
  static const nonceLength = 16;

  static final _random = Random.secure();

  static Uint8List newSecret() => Uint8List.fromList(
    List.generate(secretLength, (_) => _random.nextInt(256)),
  );

  /// `ferret://pair?o=<base64url offer>`
  static Uri offerUri(PairingOffer offer) => Uri(
    scheme: scheme,
    host: 'pair',
    queryParameters: {
      'o': base64Url.encode(offer.writeToBuffer()).replaceAll('=', ''),
    },
  );

  /// The offer in a link or scanned text, or null when it isn't one.
  static PairingOffer? parseOffer(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || uri.scheme != scheme || uri.host != 'pair') {
      return null;
    }

    final encoded = uri.queryParameters['o'];
    if (encoded == null) {
      return null;
    }

    try {
      return PairingOffer.fromBuffer(
        base64Url.decode(base64Url.normalize(encoded)),
      );
    } on Object {
      return null;
    }
  }

  /// What the scanner sends to prove it saw the offer.
  static Future<Uint8List> requestProof(
    List<int> secret,
    List<int> handshakeHash,
  ) => NoiseCrypto.hmac(secret, handshakeHash);

  /// What the offerer answers with, to prove it still holds the secret.
  static Future<Uint8List> responseProof(
    List<int> secret,
    List<int> handshakeHash,
  ) => NoiseCrypto.hmac(secret, [...handshakeHash, ...utf8.encode('response')]);

  /// A fresh nonce for one code comparison.
  static Uint8List newNonce() => Uint8List.fromList(
    List.generate(nonceLength, (_) => _random.nextInt(256)),
  );

  /// What the requester sends before it learns the answerer's nonce, so it
  /// can't pick its own afterwards.
  static Future<Uint8List> commitment(List<int> nonce) =>
      NoiseCrypto.hash(nonce);

  /// Six digits both screens show when pairing without a QR code. They match
  /// only when both sides share one handshake, so no one sits in between.
  ///
  /// The handshake hash alone is not enough for a code this short: someone
  /// in the middle runs two handshakes and can retry keys until both hashes
  /// give the same six digits, about a thousand tries. The two nonces stop
  /// that. The requester commits to its nonce first, the answerer then picks
  /// its own, and only then is the first one revealed, so each side's nonce
  /// was fixed before it saw the other's and nobody can aim at a code. One
  /// attempt matches by luck once in a million.
  static Future<String> comparisonCode(
    List<int> handshakeHash, {
    required List<int> requesterNonce,
    required List<int> answererNonce,
  }) async {
    final mac = await NoiseCrypto.hmac(handshakeHash, [
      ...utf8.encode('ferret-compare'),
      ...requesterNonce,
      ...answererNonce,
    ]);
    final value = ByteData.sublistView(mac).getUint32(0) % 1000000;
    return value.toString().padLeft(6, '0');
  }

  /// Compares in constant time.
  static bool same(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }

    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }

    return difference == 0;
  }
}
