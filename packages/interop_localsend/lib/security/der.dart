import 'dart:convert';
import 'dart:typed_data';

/// Writes the few ASN.1 DER values an X.509 certificate and an RSA key
/// need.
abstract final class Der {
  static const _sequenceTag = 0x30;
  static const _setTag = 0x31;
  static const _integerTag = 0x02;
  static const _bitStringTag = 0x03;
  static const _octetStringTag = 0x04;
  static const _nullTag = 0x05;
  static const _oidTag = 0x06;
  static const _utf8Tag = 0x0c;
  static const _utcTimeTag = 0x17;
  static const _generalizedTimeTag = 0x18;
  static const _explicitBase = 0xa0;

  static Uint8List sequence(List<List<int>> children) =>
      _wrap(_sequenceTag, _join(children));

  static Uint8List set(List<List<int>> children) =>
      _wrap(_setTag, _join(children));

  /// A non-negative INTEGER, with the leading zero DER wants when the top
  /// bit is set.
  static Uint8List integer(BigInt value) {
    if (value.isNegative) {
      throw ArgumentError.value(value, 'value', 'must not be negative');
    }

    final bytes = <int>[];
    var rest = value;
    while (rest > BigInt.zero) {
      bytes.insert(0, (rest & BigInt.from(0xff)).toInt());
      rest >>= 8;
    }

    if (bytes.isEmpty || bytes.first & 0x80 != 0) {
      bytes.insert(0, 0);
    }

    return _wrap(_integerTag, bytes);
  }

  static Uint8List bitString(List<int> bytes) =>
      _wrap(_bitStringTag, [0, ...bytes]);

  static Uint8List octetString(List<int> bytes) =>
      _wrap(_octetStringTag, bytes);

  static Uint8List nullValue() => _wrap(_nullTag, const []);

  /// An OBJECT IDENTIFIER from dotted notation, such as `2.5.4.3`.
  static Uint8List oid(String dotted) {
    final arcs = [for (final arc in dotted.split('.')) int.parse(arc)];
    final bytes = <int>[arcs[0] * 40 + arcs[1]];
    for (final arc in arcs.skip(2)) {
      bytes.addAll(_base128(arc));
    }

    return _wrap(_oidTag, bytes);
  }

  static Uint8List utf8String(String text) =>
      _wrap(_utf8Tag, utf8.encode(text));

  /// A Time: UTCTime through 2049, GeneralizedTime after, as X.509 asks.
  static Uint8List time(DateTime moment) {
    final utc = moment.toUtc();
    final rest =
        '${_two(utc.month)}${_two(utc.day)}'
        '${_two(utc.hour)}${_two(utc.minute)}${_two(utc.second)}Z';
    if (utc.year < 2050) {
      return _wrap(_utcTimeTag, ascii.encode('${_two(utc.year % 100)}$rest'));
    }

    return _wrap(
      _generalizedTimeTag,
      ascii.encode('${utc.year.toString().padLeft(4, '0')}$rest'),
    );
  }

  /// `[number] EXPLICIT` around [content].
  static Uint8List explicit(int number, List<int> content) =>
      _wrap(_explicitBase | number, content);

  static Uint8List _wrap(int tag, List<int> content) =>
      Uint8List.fromList([tag, ..._length(content.length), ...content]);

  static List<int> _length(int length) {
    if (length < 0x80) {
      return [length];
    }

    final bytes = <int>[];
    var rest = length;
    while (rest > 0) {
      bytes.insert(0, rest & 0xff);
      rest >>= 8;
    }

    return [0x80 | bytes.length, ...bytes];
  }

  static List<int> _base128(int arc) {
    final bytes = <int>[arc & 0x7f];
    var rest = arc >> 7;
    while (rest > 0) {
      bytes.insert(0, 0x80 | (rest & 0x7f));
      rest >>= 7;
    }

    return bytes;
  }

  static List<int> _join(List<List<int>> parts) => [
    for (final part in parts) ...part,
  ];

  static String _two(int value) => value.toString().padLeft(2, '0');
}
