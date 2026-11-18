import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// HKDF with SHA-256 (RFC 5869), the only key derivation Quick Share uses.
abstract final class Hkdf {
  static const _hashLength = 32;

  /// Derives [length] bytes from [key], with [salt] and [info].
  static Uint8List derive({
    required List<int> key,
    required List<int> salt,
    required List<int> info,
    int length = _hashLength,
  }) {
    if (length > 255 * _hashLength) {
      throw ArgumentError.value(length, 'length', 'Too long for HKDF');
    }

    final pseudoRandomKey = Hmac(sha256, salt).convert(key).bytes;
    final expander = Hmac(sha256, pseudoRandomKey);
    final output = BytesBuilder(copy: false);
    var block = const <int>[];
    for (var counter = 1; output.length < length; counter++) {
      block = expander.convert([...block, ...info, counter]).bytes;
      output.add(block);
    }

    return Uint8List.sublistView(output.takeBytes(), 0, length);
  }
}
