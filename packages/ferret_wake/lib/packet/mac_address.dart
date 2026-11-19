import 'dart:typed_data';

/// Reads and writes 6-byte hardware (MAC) addresses.
abstract final class MacAddress {
  static const length = 6;

  static final _separators = RegExp('[:.-]');
  static final _hex = RegExp(r'^[0-9a-fA-F]{12}$');

  /// [text] as bytes, written as `3c:22:fb:12:34:56`, `3C-22-FB-12-34-56`,
  /// `3c22.fb12.3456` or `3c22fb123456`. Null when it isn't one, or when
  /// it is all zeros (a card without an address of its own).
  static Uint8List? parse(String text) {
    final digits = text.trim().replaceAll(_separators, '');
    if (!_hex.hasMatch(digits)) {
      return null;
    }

    final bytes = Uint8List(length);
    for (var index = 0; index < length; index++) {
      bytes[index] = int.parse(
        digits.substring(index * 2, index * 2 + 2),
        radix: 16,
      );
    }

    if (!isUsable(bytes)) {
      return null;
    }

    return bytes;
  }

  /// Whether [mac] is six bytes and not all zeros.
  static bool isUsable(List<int> mac) =>
      mac.length == length && mac.any((byte) => byte != 0);

  /// [mac] as `3c:22:fb:12:34:56`.
  static String format(List<int> mac) => [
    for (final byte in mac) byte.toRadixString(16).padLeft(2, '0'),
  ].join(':');
}
