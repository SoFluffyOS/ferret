import 'dart:typed_data';

/// What kind of payload follows a mirroring stream header.
enum MirrorPayloadType {
  /// Encrypted H.264 pictures.
  video,

  /// The unencrypted decoder configuration (avcC), sent first and again
  /// when the picture changes size.
  codec,

  /// Sent about once a second to keep the stream alive.
  heartbeat,

  /// Anything else, such as the phone's streaming reports. Skipped.
  other,
}

/// The 128-byte header in front of every payload on the mirroring stream.
class MirrorPacketHeader {
  const MirrorPacketHeader({
    required this.payloadSize,
    required this.type,
    required this.option,
    required this.timestamp,
    this.width = 0,
    this.height = 0,
    this.sourceWidth = 0,
    this.sourceHeight = 0,
  });

  /// Reads the header at the start of [bytes], which must hold [length]
  /// bytes. Everything in it is little-endian.
  factory MirrorPacketHeader.parse(Uint8List bytes) {
    if (bytes.length < length) {
      throw const FormatException('Mirror stream header too short');
    }

    final data = ByteData.sublistView(bytes, 0, length);
    final type = switch (bytes[4]) {
      0 => MirrorPayloadType.video,
      1 => MirrorPayloadType.codec,
      2 => MirrorPayloadType.heartbeat,
      _ => MirrorPayloadType.other,
    };
    if (type != MirrorPayloadType.codec) {
      return MirrorPacketHeader(
        payloadSize: data.getUint32(0, Endian.little),
        type: type,
        option: data.getUint16(6, Endian.little),
        timestamp: data.getUint64(8, Endian.little),
      );
    }

    return MirrorPacketHeader(
      payloadSize: data.getUint32(0, Endian.little),
      type: type,
      option: data.getUint16(6, Endian.little),
      timestamp: data.getUint64(8, Endian.little),
      sourceWidth: _size(data, 40),
      sourceHeight: _size(data, 44),
      width: _size(data, 56),
      height: _size(data, 60),
    );
  }

  static const length = 128;

  final int payloadSize;
  final MirrorPayloadType type;

  /// Bytes 6 and 7. On a codec packet, bit 6 set means the phone paused
  /// the picture (its screen went to sleep).
  final int option;

  /// The phone's clock as NTP fixed point: seconds in the high 32 bits,
  /// the fraction of a second in the low 32.
  final int timestamp;

  /// Codec packets only: the size of the encoded picture.
  final int width;
  final int height;

  /// Codec packets only: the size of the phone's screen.
  final int sourceWidth;
  final int sourceHeight;

  /// [timestamp] in microseconds.
  int get timestampUs {
    final seconds = (timestamp >> 32) & 0xffffffff;
    final fraction = timestamp & 0xffffffff;
    return seconds * 1000000 + ((fraction * 1000000) >> 32);
  }

  /// The sizes are whole numbers stored as 32-bit floats.
  static int _size(ByteData data, int offset) {
    final value = data.getFloat32(offset, Endian.little);
    if (!value.isFinite || value < 0 || value > 65535) {
      return 0;
    }

    return value.round();
  }
}
