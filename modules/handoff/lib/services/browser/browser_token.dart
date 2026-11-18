import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// The secret an extension gets once the user allowed it. Ferret keeps only
/// its hash.
abstract final class BrowserToken {
  static final _random = Random.secure();

  static const _bytes = 32;

  static String create() => base64Url
      .encode([
        for (var index = 0; index < _bytes; index++) _random.nextInt(256),
      ])
      .replaceAll('=', '');

  static String hash(String token) =>
      base64.encode(sha256.convert(utf8.encode(token)).bytes);

  /// Compares in constant time, so timing doesn't leak how much matched.
  static bool matches(String token, String expectedHash) {
    final actual = utf8.encode(hash(token));
    final expected = utf8.encode(expectedHash);
    if (actual.length != expected.length) {
      return false;
    }

    var difference = 0;
    for (var index = 0; index < actual.length; index++) {
      difference |= actual[index] ^ expected[index];
    }

    return difference == 0;
  }

  /// A short random id, such as for a client or a request.
  static String newId() => [
    for (var index = 0; index < 8; index++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
