import 'dart:convert';
import 'dart:typed_data';

/// Reads and writes DNS names.
abstract final class DnsWire {
  static const maxLabel = 63;
  static const maxTxtEntry = 255;
  static const _pointerMask = 0xc0;
  static const _maxJumps = 16;

  /// The wire form of [labels], without compression.
  static Uint8List encodeName(List<String> labels) {
    final bytes = BytesBuilder();
    for (final label in labels) {
      final encoded = utf8.encode(label);
      if (encoded.isEmpty || encoded.length > maxLabel) {
        throw ArgumentError.value(label, 'labels', 'Not a DNS label');
      }

      bytes
        ..addByte(encoded.length)
        ..add(encoded);
    }

    bytes.addByte(0);
    return bytes.takeBytes();
  }

  /// Reads the name at [offset] of [packet], following compression
  /// pointers. Returns the labels and the offset right after the name,
  /// or null when the packet is malformed.
  static (List<String>, int)? readName(Uint8List packet, int offset) {
    final labels = <String>[];
    var position = offset;
    int? end;
    for (var jumps = 0; jumps <= _maxJumps;) {
      if (position >= packet.length) {
        return null;
      }

      final length = packet[position];
      if (length == 0) {
        return (labels, end ?? position + 1);
      }

      if (length & _pointerMask == _pointerMask) {
        if (position + 1 >= packet.length) {
          return null;
        }

        end ??= position + 2;
        position = ((length & ~_pointerMask) << 8) | packet[position + 1];
        jumps++;
        continue;
      }

      if (length > maxLabel || position + 1 + length > packet.length) {
        return null;
      }

      labels.add(
        utf8.decode(
          Uint8List.sublistView(packet, position + 1, position + 1 + length),
          allowMalformed: true,
        ),
      );
      position += 1 + length;
    }

    return null;
  }

  /// Whether two names are the same. DNS names ignore ASCII case.
  static bool sameName(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index].toLowerCase() != second[index].toLowerCase()) {
        return false;
      }
    }

    return true;
  }
}
