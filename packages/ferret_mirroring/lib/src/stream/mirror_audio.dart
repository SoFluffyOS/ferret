import 'dart:typed_data';

/// How a mirrored device's sound is encoded.
enum MirrorAudioCodec {
  /// Opus, one packet per [MirrorAudioPacket].
  opus,

  /// Signed 16-bit little-endian samples, channels interleaved. No
  /// decoder needed, at about 1.5 Mbit/s for 48 kHz stereo.
  pcm,
}

/// What a sink needs before the first packet of sound.
class MirrorAudioConfig {
  const MirrorAudioConfig({
    required this.codec,
    this.sampleRate = 48000,
    this.channels = 2,
  });

  final MirrorAudioCodec codec;
  final int sampleRate;
  final int channels;

  @override
  bool operator ==(Object other) =>
      other is MirrorAudioConfig &&
      other.codec == codec &&
      other.sampleRate == sampleRate &&
      other.channels == channels;

  @override
  int get hashCode => Object.hash(codec, sampleRate, channels);
}

/// A few milliseconds of a mirrored device's sound.
class MirrorAudioPacket {
  const MirrorAudioPacket({required this.data, required this.ptsUs});

  final Uint8List data;

  /// When it was captured, in microseconds on the same clock as the
  /// pictures of the feed it came with.
  final int ptsUs;
}

/// Why a feed that was asked for sound has none.
enum AudioUnavailable {
  /// The other device can't capture its sound, such as an Android older
  /// than the route needs.
  unsupported,

  /// Its owner hasn't allowed sound to be sent.
  notAllowed,

  /// Capturing or encoding the sound failed there.
  failed,
}
