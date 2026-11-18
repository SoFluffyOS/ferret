import 'dart:typed_data';

import 'package:ferret_mirror_airplay/src/stream/mirror_packet.dart';
import 'package:ferret_mirror_airplay/src/stream/mirror_packet_header.dart';

/// Cuts the mirroring TCP stream into packets, however the bytes arrive.
class MirrorPacketReader {
  /// Larger than any picture a phone sends; a bigger claim means the
  /// stream is broken or hostile.
  static const maxPayload = 16 * 1024 * 1024;

  final BytesBuilder _pending = BytesBuilder(copy: false);
  MirrorPacketHeader? _header;

  /// Adds [chunk] and returns every packet it completed. Throws a
  /// [FormatException] when a header claims more than [maxPayload].
  List<MirrorPacket> add(Uint8List chunk) {
    _pending.add(chunk);
    final bytes = _pending.takeBytes();
    final packets = <MirrorPacket>[];
    var offset = 0;
    while (true) {
      var header = _header;
      if (header == null) {
        if (bytes.length - offset < MirrorPacketHeader.length) {
          break;
        }

        header = MirrorPacketHeader.parse(
          Uint8List.sublistView(bytes, offset),
        );
        if (header.payloadSize > maxPayload) {
          throw const FormatException('Mirror stream payload too large');
        }

        _header = header;
        offset += MirrorPacketHeader.length;
      }

      if (bytes.length - offset < header.payloadSize) {
        break;
      }

      packets.add(
        MirrorPacket(
          header,
          Uint8List.sublistView(bytes, offset, offset + header.payloadSize),
        ),
      );
      offset += header.payloadSize;
      _header = null;
    }

    if (offset < bytes.length) {
      _pending.add(Uint8List.sublistView(bytes, offset));
    }

    return packets;
  }
}
