import 'dart:typed_data';

/// What an Opus packet says about itself in its first bytes (RFC 6716,
/// section 3.1), without decoding it.
abstract final class OpusPacket {
  /// Opus always counts time at 48 kHz, whatever was encoded.
  static const int sampleRate = 48000;

  static const List<int> _silkFrameSamples = [480, 960, 1920, 2880];
  static const List<int> _hybridFrameSamples = [480, 960];
  static const List<int> _celtFrameSamples = [120, 240, 480, 960];

  /// How many samples per channel [packet] holds, at 48 kHz. 0 for
  /// something that can't be an Opus packet.
  static int samplesOf(Uint8List packet) {
    if (packet.isEmpty) {
      return 0;
    }

    final toc = packet[0];
    final frames = switch (toc & 0x03) {
      0 => 1,
      1 || 2 => 2,
      _ => _frameCountOf(packet),
    };

    return frames * _frameSamplesOf(toc >> 3);
  }

  static Duration durationOf(Uint8List packet) =>
      Duration(microseconds: samplesOf(packet) * 1000000 ~/ sampleRate);

  static int _frameCountOf(Uint8List packet) {
    if (packet.length < 2) {
      return 0;
    }

    return packet[1] & 0x3F;
  }

  static int _frameSamplesOf(int config) {
    if (config < 12) {
      return _silkFrameSamples[config & 0x03];
    }

    if (config < 16) {
      return _hybridFrameSamples[config & 0x01];
    }

    return _celtFrameSamples[config & 0x03];
  }
}
