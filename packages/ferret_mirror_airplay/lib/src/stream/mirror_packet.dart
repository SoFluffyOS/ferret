import 'dart:typed_data';

import 'package:ferret_mirror_airplay/src/stream/mirror_packet_header.dart';

/// One header and its payload, as read off the mirroring stream.
class MirrorPacket {
  const MirrorPacket(this.header, this.payload);

  final MirrorPacketHeader header;
  final Uint8List payload;
}
