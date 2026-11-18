import 'dart:convert';
import 'dart:typed_data';

/// Reads Apple's binary property list format (`bplist00`), which AirPlay
/// uses for its request and response bodies.
///
/// Values come back as plain Dart: `null`, `bool`, `int`, `double`,
/// `String`, `Uint8List` for data, `DateTime`, `List<Object?>` and
/// `Map<String, Object?>`. The bytes come from the network, so every
/// offset and length is checked; anything off throws a [FormatException].
class BinaryPlistDecoder {
  BinaryPlistDecoder._(this._bytes) : _view = ByteData.sublistView(_bytes);

  static const _magic = 'bplist00';
  static const _trailerLength = 32;
  static const _maxDepth = 32;

  /// Objects one plist may hold, so shared references can't be used to
  /// make a small body expand without end.
  static const _maxObjects = 65536;

  /// Seconds between the Unix epoch and 2001-01-01, where plist dates start.
  static const _appleEpochSeconds = 978307200;

  final Uint8List _bytes;
  final ByteData _view;
  late final int _offsetSize;
  late final int _refSize;
  late final int _objectCount;
  late final int _tableOffset;
  int _decoded = 0;

  static Object? decode(Uint8List bytes) {
    final decoder = BinaryPlistDecoder._(bytes);
    return decoder._decode();
  }

  /// The dictionary at the top of [bytes], or an empty one when the plist
  /// holds something else or can't be read.
  static Map<String, Object?> decodeDict(Uint8List bytes) {
    try {
      if (decode(bytes) case final Map<String, Object?> dict) {
        return dict;
      }
    } on FormatException {
      return const {};
    }

    return const {};
  }

  Object? _decode() {
    if (_bytes.length < _magic.length + _trailerLength) {
      throw const FormatException('Binary plist too short');
    }

    if (ascii.decode(_bytes.sublist(0, 6), allowInvalid: true) != 'bplist') {
      throw const FormatException('Not a binary plist');
    }

    final trailer = _bytes.length - _trailerLength;
    _offsetSize = _bytes[trailer + 6];
    _refSize = _bytes[trailer + 7];
    _objectCount = _view.getUint64(trailer + 8);
    final top = _view.getUint64(trailer + 16);
    _tableOffset = _view.getUint64(trailer + 24);
    final sizesValid =
        _offsetSize >= 1 && _offsetSize <= 8 && _refSize >= 1 && _refSize <= 8;
    if (!sizesValid || _objectCount < 0 || _objectCount > _bytes.length) {
      throw const FormatException('Bad binary plist trailer');
    }

    final tableEnd = _tableOffset + _objectCount * _offsetSize;
    if (_tableOffset < _magic.length || tableEnd > trailer) {
      throw const FormatException('Bad binary plist offset table');
    }

    return _object(top, 0);
  }

  Object? _object(int index, int depth) {
    if (index < 0 || index >= _objectCount) {
      throw const FormatException('Binary plist reference out of range');
    }

    if (depth > _maxDepth) {
      throw const FormatException('Binary plist nested too deep');
    }

    _decoded++;
    if (_decoded > _maxObjects) {
      throw const FormatException('Binary plist too large');
    }

    final offset = _uint(_tableOffset + index * _offsetSize, _offsetSize);
    _check(offset, 1);
    final marker = _bytes[offset];
    final kind = marker >> 4;
    final info = marker & 0x0f;
    return switch (kind) {
      0x0 => _simple(info),
      0x1 => _int(offset + 1, 1 << info),
      0x2 => _real(offset + 1, 1 << info),
      0x3 => _date(offset + 1),
      0x4 => _data(offset, info),
      0x5 => _asciiString(offset, info),
      0x6 => _utf16String(offset, info),
      0x8 => _uint(offset + 1, info + 1),
      0xa => _array(offset, info, depth),
      0xd => _dict(offset, info, depth),
      _ => throw FormatException('Unknown binary plist type $kind'),
    };
  }

  Object? _simple(int info) => switch (info) {
    0x0 => null,
    0x8 => false,
    0x9 => true,
    _ => throw FormatException('Unknown binary plist value $info'),
  };

  /// Integers of up to 8 bytes are read as stored; 8 bytes are signed, so
  /// an unsigned 64-bit value keeps its bits. Of 16 bytes, the low 8 count.
  int _int(int offset, int size) {
    if (size > 16) {
      throw const FormatException('Binary plist integer too wide');
    }

    if (size == 16) {
      _check(offset, 16);
      return _view.getInt64(offset + 8);
    }

    if (size == 8) {
      _check(offset, 8);
      return _view.getInt64(offset);
    }

    return _uint(offset, size);
  }

  double _real(int offset, int size) {
    _check(offset, size);
    return switch (size) {
      4 => _view.getFloat32(offset),
      8 => _view.getFloat64(offset),
      _ => throw FormatException('Binary plist real of $size bytes'),
    };
  }

  DateTime _date(int offset) {
    _check(offset, 8);
    final seconds = _view.getFloat64(offset);
    if (!seconds.isFinite) {
      throw const FormatException('Bad binary plist date');
    }

    final micros = ((seconds + _appleEpochSeconds) * 1000000).round();
    return DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
  }

  Uint8List _data(int offset, int info) {
    final (start, length) = _extent(offset, info);
    _check(start, length);
    return Uint8List.sublistView(_bytes, start, start + length);
  }

  String _asciiString(int offset, int info) {
    final (start, length) = _extent(offset, info);
    _check(start, length);
    return latin1.decode(Uint8List.sublistView(_bytes, start, start + length));
  }

  String _utf16String(int offset, int info) {
    final (start, length) = _extent(offset, info);
    _check(start, length * 2);
    return String.fromCharCodes([
      for (var index = 0; index < length; index++)
        _view.getUint16(start + index * 2),
    ]);
  }

  List<Object?> _array(int offset, int info, int depth) {
    final (start, count) = _extent(offset, info);
    _check(start, count * _refSize);
    return [
      for (var index = 0; index < count; index++)
        _object(_uint(start + index * _refSize, _refSize), depth + 1),
    ];
  }

  Map<String, Object?> _dict(int offset, int info, int depth) {
    final (start, count) = _extent(offset, info);
    _check(start, count * _refSize * 2);
    final values = start + count * _refSize;
    final dict = <String, Object?>{};
    for (var index = 0; index < count; index++) {
      final key = _object(_uint(start + index * _refSize, _refSize), depth + 1);
      if (key is! String) {
        throw const FormatException('Binary plist key is not a string');
      }

      dict[key] = _object(
        _uint(values + index * _refSize, _refSize),
        depth + 1,
      );
    }

    return dict;
  }

  /// Where a sized object's content starts and how many items it has. A
  /// count of 15 or more is stored as an integer object right after the
  /// marker.
  (int start, int count) _extent(int offset, int info) {
    if (info != 0x0f) {
      return (offset + 1, info);
    }

    _check(offset + 1, 1);
    final marker = _bytes[offset + 1];
    if (marker >> 4 != 0x1) {
      throw const FormatException('Bad binary plist length');
    }

    final size = 1 << (marker & 0x0f);
    if (size > 8) {
      throw const FormatException('Bad binary plist length');
    }

    final count = _uint(offset + 2, size);
    if (count < 0 || count > _bytes.length) {
      throw const FormatException('Bad binary plist length');
    }

    return (offset + 2 + size, count);
  }

  int _uint(int offset, int size) {
    _check(offset, size);
    var value = 0;
    for (var index = 0; index < size; index++) {
      value = (value << 8) | _bytes[offset + index];
    }

    return value;
  }

  void _check(int offset, int length) {
    if (offset < 0 || length < 0 || offset + length > _bytes.length) {
      throw const FormatException('Binary plist runs past its end');
    }
  }
}
