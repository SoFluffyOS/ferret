import 'dart:math';
import 'dart:typed_data';

/// Small helpers for secrets and random values.
abstract final class SecureBytes {
  static final _random = Random.secure();

  /// [length] random bytes, from [random] or the system's secure source.
  static Uint8List random(int length, [Random? random]) {
    final source = random ?? _random;
    final bytes = Uint8List(length);
    for (var index = 0; index < length; index++) {
      bytes[index] = source.nextInt(256);
    }

    return bytes;
  }

  /// Compares without stopping at the first difference, so timing doesn't
  /// tell how much of a MAC or commitment matched.
  static bool same(List<int> first, List<int> second) {
    if (first.length != second.length) {
      return false;
    }

    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }

    return difference == 0;
  }
}
