import 'dart:typed_data';

/// Signed 16-bit little-endian samples, as the sinks without a decoder
/// take them.
abstract final class PcmSamples {
  static const int bytesPerSample = 2;
  static const int _fullScale = 32768;

  /// [data] with every sample multiplied by [volume] (0 to 1). The same
  /// bytes when there is nothing to change.
  static Uint8List scaled(Uint8List data, double volume) {
    if (volume >= 1) {
      return data;
    }

    final count = data.length ~/ bytesPerSample;
    final source = ByteData.sublistView(data);
    final scaled = ByteData(count * bytesPerSample);
    for (var index = 0; index < count; index++) {
      final offset = index * bytesPerSample;
      final sample = source.getInt16(offset, Endian.little) * volume;
      scaled.setInt16(offset, sample.round(), Endian.little);
    }

    return scaled.buffer.asUint8List();
  }

  /// The loudest sample in [data], from 0 to 1.
  static double peakOf(Uint8List data) {
    final count = data.length ~/ bytesPerSample;
    final samples = ByteData.sublistView(data);
    var loudest = 0;
    for (var index = 0; index < count; index++) {
      final sample = samples.getInt16(index * bytesPerSample, Endian.little);
      final size = sample.abs();
      if (size > loudest) {
        loudest = size;
      }
    }

    return loudest / _fullScale;
  }

  /// How long [byteCount] bytes play for.
  static Duration durationOf(
    int byteCount, {
    required int sampleRate,
    required int channels,
  }) {
    final frames = byteCount ~/ (bytesPerSample * channels);
    return Duration(microseconds: frames * 1000000 ~/ sampleRate);
  }
}
