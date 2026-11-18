import 'dart:typed_data';

/// Writes Apple's binary property list format (`bplist00`) from plain Dart
/// values: `null`, `bool`, `int`, `double`, `String`, `Uint8List` (data),
/// `DateTime`, `List` and `Map<String, Object?>`.
class BinaryPlistEncoder {
  BinaryPlistEncoder._();

  static const _appleEpochSeconds = 978307200;

  /// Each object, flattened; arrays and dictionaries hold indexes.
  final List<Object?> _objects = [];
  final Map<int, List<int>> _children = {};

  static Uint8List encode(Object? value) {
    final encoder = BinaryPlistEncoder._();
    encoder._flatten(value);
    return encoder._write();
  }

  int _flatten(Object? value) {
    final index = _objects.length;
    _objects.add(value);
    if (value is Uint8List) {
      return index;
    }

    if (value is List) {
      _children[index] = [for (final item in value) _flatten(item)];
      return index;
    }

    if (value is Map) {
      final keys = [for (final key in value.keys) _flatten('$key')];
      final values = [for (final item in value.values) _flatten(item)];
      _children[index] = [...keys, ...values];
    }

    return index;
  }

  Uint8List _write() {
    final refSize = _sizeFor(_objects.length);
    final out = BytesBuilder()..add('bplist00'.codeUnits);
    final offsets = <int>[];
    for (var index = 0; index < _objects.length; index++) {
      offsets.add(out.length);
      _writeObject(out, _objects[index], _children[index], refSize);
    }

    final tableOffset = out.length;
    final offsetSize = _sizeFor(tableOffset);
    for (final offset in offsets) {
      out.add(_uint(offset, offsetSize));
    }

    out
      ..add(const [0, 0, 0, 0, 0, 0])
      ..addByte(offsetSize)
      ..addByte(refSize)
      ..add(_uint(_objects.length, 8))
      ..add(_uint(0, 8))
      ..add(_uint(tableOffset, 8));
    return out.takeBytes();
  }

  void _writeObject(
    BytesBuilder out,
    Object? value,
    List<int>? children,
    int refSize,
  ) {
    switch (value) {
      case null:
        out.addByte(0x00);
      case false:
        out.addByte(0x08);
      case true:
        out.addByte(0x09);
      case final int number:
        _writeInt(out, number);
      case final double number:
        out
          ..addByte(0x23)
          ..add(_float64(number));
      case final DateTime date:
        final seconds =
            date.microsecondsSinceEpoch / 1000000 - _appleEpochSeconds;
        out
          ..addByte(0x33)
          ..add(_float64(seconds));
      case final Uint8List data:
        _writeMarker(out, 0x4, data.length);
        out.add(data);
      case final String text:
        _writeString(out, text);
      case List():
        final items = children ?? const [];
        _writeMarker(out, 0xa, items.length);
        _writeRefs(out, items, refSize);
      case Map():
        final items = children ?? const [];
        _writeMarker(out, 0xd, items.length ~/ 2);
        _writeRefs(out, items, refSize);
      default:
        throw ArgumentError.value(value, 'value', 'Not a plist value');
    }
  }

  void _writeInt(BytesBuilder out, int number) {
    if (number < 0 || number > 0xffffffff) {
      out
        ..addByte(0x13)
        ..add(_uint(number, 8));
      return;
    }

    final size = _sizeFor(number);
    final power = switch (size) {
      1 => 0,
      2 => 1,
      _ => 2,
    };
    out
      ..addByte(0x10 | power)
      ..add(_uint(number, 1 << power));
  }

  void _writeString(BytesBuilder out, String text) {
    final units = text.codeUnits;
    if (units.every((unit) => unit < 0x80)) {
      _writeMarker(out, 0x5, units.length);
      out.add(units);
      return;
    }

    _writeMarker(out, 0x6, units.length);
    for (final unit in units) {
      out.add(_uint(unit, 2));
    }
  }

  void _writeMarker(BytesBuilder out, int kind, int count) {
    if (count < 0x0f) {
      out.addByte(kind << 4 | count);
      return;
    }

    out.addByte(kind << 4 | 0x0f);
    _writeInt(out, count);
  }

  void _writeRefs(BytesBuilder out, List<int> refs, int refSize) {
    for (final ref in refs) {
      out.add(_uint(ref, refSize));
    }
  }

  /// Bytes needed for [value]: 1, 2, 4 or 8.
  int _sizeFor(int value) {
    if (value < 0x100) {
      return 1;
    }

    if (value < 0x10000) {
      return 2;
    }

    if (value <= 0xffffffff) {
      return 4;
    }

    return 8;
  }

  Uint8List _uint(int value, int size) {
    final bytes = Uint8List(size);
    var rest = value;
    for (var index = size - 1; index >= 0; index--) {
      bytes[index] = rest & 0xff;
      rest >>= 8;
    }

    return bytes;
  }

  Uint8List _float64(double value) {
    final data = ByteData(8)..setFloat64(0, value);
    return data.buffer.asUint8List();
  }
}
