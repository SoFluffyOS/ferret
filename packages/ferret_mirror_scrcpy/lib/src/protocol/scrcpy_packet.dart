import 'dart:typed_data';

/// What scrcpy's server writes on its video socket, in order.
sealed class ScrcpyPacket {
  const ScrcpyPacket();
}

/// The device's name, sent once on the first socket.
class DeviceMetaPacket extends ScrcpyPacket {
  const DeviceMetaPacket(this.deviceName);

  final String deviceName;
}

/// The stream's codec id, sent once. 0 and 1 are not codecs: the device
/// turned the stream off, or failed to set it up.
class CodecPacket extends ScrcpyPacket {
  const CodecPacket(this.codecId);

  static const int h264 = 0x68323634;
  static const int disabled = 0;
  static const int configurationError = 1;

  final int codecId;
}

/// A new capture session: the first one, and one more each time the picture
/// changes size, such as when the device rotates.
class SessionPacket extends ScrcpyPacket {
  const SessionPacket({required this.width, required this.height});

  final int width;
  final int height;
}

/// One buffer from the device's encoder.
class MediaPacket extends ScrcpyPacket {
  const MediaPacket({
    required this.data,
    required this.ptsUs,
    required this.isConfig,
    required this.isKeyframe,
  });

  final Uint8List data;

  /// 0 for a config packet, which has no time of its own.
  final int ptsUs;

  /// Parameter sets rather than a picture.
  final bool isConfig;
  final bool isKeyframe;
}
