import 'dart:typed_data';

/// H.264 as Android's encoder writes it: NAL units separated by start codes
/// (00 00 01 or 00 00 00 01).
abstract final class AnnexB {
  static const int sequenceParameterSet = 7;
  static const int pictureParameterSet = 8;

  /// The NAL units in [data], without their start codes.
  static List<Uint8List> units(Uint8List data) {
    final units = <Uint8List>[];
    int? unitStart;
    var index = 0;

    while (index + 2 < data.length) {
      final isStartCode =
          data[index] == 0 && data[index + 1] == 0 && data[index + 2] == 1;
      if (!isStartCode) {
        index++;
        continue;
      }

      if (unitStart != null) {
        _addUnit(units, data, unitStart, index);
      }

      unitStart = index + 3;
      index += 3;
    }

    if (unitStart != null) {
      _addUnit(units, data, unitStart, data.length);
    }

    return units;
  }

  static int typeOf(Uint8List unit) => unit[0] & 0x1f;

  /// A unit's payload with the bytes the encoder slipped in to keep start
  /// codes out of it (the 03 of every 00 00 03) taken out again.
  static Uint8List payload(Uint8List unit) {
    final payload = BytesBuilder();
    var zeros = 0;
    for (final byte in unit.skip(1)) {
      if (zeros >= 2 && byte == 3) {
        zeros = 0;
        continue;
      }

      zeros = switch (byte) {
        0 => zeros + 1,
        _ => 0,
      };
      payload.addByte(byte);
    }

    return payload.takeBytes();
  }

  static void _addUnit(
    List<Uint8List> units,
    Uint8List data,
    int start,
    int nextStartCode,
  ) {
    var end = nextStartCode;
    final isLast = nextStartCode == data.length;
    while (!isLast && end > start && data[end - 1] == 0) {
      end--;
    }

    if (end > start) {
      units.add(Uint8List.sublistView(data, start, end));
    }
  }
}
