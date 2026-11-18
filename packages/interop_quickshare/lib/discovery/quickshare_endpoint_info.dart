import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:interop_quickshare/crypto/crypto.dart';
import 'package:interop_quickshare/models/models.dart';

/// How a Quick Share device describes itself, in the mDNS TXT record and
/// again when it connects: its kind and the name people see.
///
/// Nothing in it is proven. Any device on the network can claim any name.
class QuickShareEndpointInfo {
  const QuickShareEndpointInfo({
    required this.name,
    this.kind = QuickShareDeviceKind.unknown,
  });

  /// Names are cut to this many bytes, so the TXT record always fits.
  static const maxNameBytes = 96;
  static const _identityLength = 16;
  static const _hiddenBit = 0x10;

  final String name;
  final QuickShareDeviceKind kind;

  /// Reads the binary form. Returns null when it is cut short, or when
  /// the device hides its name, which only its owner's contacts can read.
  static QuickShareEndpointInfo? decode(List<int> bytes) {
    const nameStart = 1 + _identityLength + 1;
    if (bytes.length < nameStart || bytes[0] & _hiddenBit != 0) {
      return null;
    }

    final nameLength = bytes[nameStart - 1];
    if (bytes.length < nameStart + nameLength) {
      return null;
    }

    return QuickShareEndpointInfo(
      name: utf8.decode(
        bytes.sublist(nameStart, nameStart + nameLength),
        allowMalformed: true,
      ),
      kind: QuickShareDeviceKind.fromCode((bytes[0] >> 1) & 0x7),
    );
  }

  /// Reads the value of the TXT record's `n` key.
  static QuickShareEndpointInfo? fromTxt(String value) {
    try {
      return decode(base64Url.decode(base64Url.normalize(value)));
    } on FormatException {
      return null;
    }
  }

  /// The binary form: a bit field with the kind, 16 bytes that only mean
  /// something between devices of one Google account (random here), then
  /// the name with its length.
  Uint8List encode([Random? random]) {
    final nameBytes = _cut(name);
    return Uint8List.fromList([
      kind.code << 1,
      ...SecureBytes.random(_identityLength, random),
      nameBytes.length,
      ...nameBytes,
    ]);
  }

  /// The value for the TXT record's `n` key.
  String toTxt([Random? random]) =>
      base64Url.encode(encode(random)).replaceAll('=', '');

  /// The name as UTF-8, shortened at a character boundary.
  static List<int> _cut(String name) {
    final bytes = <int>[];
    for (final rune in name.runes) {
      final encoded = utf8.encode(String.fromCharCode(rune));
      if (bytes.length + encoded.length > maxNameBytes) {
        break;
      }

      bytes.addAll(encoded);
    }

    return bytes;
  }
}
