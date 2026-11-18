import 'dart:typed_data';

/// Reads an H.264 parameter set bit by bit, with its Exp-Golomb numbers.
class BitReader {
  BitReader(this._bytes);

  final Uint8List _bytes;
  int _position = 0;

  int bit() {
    final byteIndex = _position >> 3;
    if (byteIndex >= _bytes.length) {
      throw const FormatException('Parameter set ends too early');
    }

    final value = (_bytes[byteIndex] >> (7 - (_position & 7))) & 1;
    _position++;
    return value;
  }

  bool flag() => bit() == 1;

  int bits(int count) {
    var value = 0;
    for (var index = 0; index < count; index++) {
      value = (value << 1) | bit();
    }

    return value;
  }

  /// ue(v) in the H.264 spec.
  int unsignedExpGolomb() {
    var leadingZeros = 0;
    while (bit() == 0) {
      leadingZeros++;
      if (leadingZeros > 32) {
        throw const FormatException('Exp-Golomb number too long');
      }
    }

    return (1 << leadingZeros) - 1 + bits(leadingZeros);
  }

  /// se(v) in the H.264 spec.
  int signedExpGolomb() {
    final code = unsignedExpGolomb();
    final magnitude = (code + 1) >> 1;
    if (code.isOdd) {
      return magnitude;
    }

    return -magnitude;
  }
}
