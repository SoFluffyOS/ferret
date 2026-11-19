import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/src/protocol/scrcpy_packet.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';

/// Turns what the audio socket carries into what a viewer wants: one
/// [FeedAudioConfigured] when the device says how it encodes its sound,
/// then a [FeedAudio] per packet. A device that can't capture its sound
/// (Android 10 and older, or a locked Android 11) says so in place of a
/// codec, and gets one [FeedAudioUnavailable].
class AudioFeedAssembler {
  static const int _sampleRate = 48000;
  static const int _stereo = 2;

  /// Where an Opus identification header ("OpusHead") says how many
  /// channels follow.
  static const int _opusHeadChannels = 9;
  static const List<int> _opusHeadMagic = [79, 112, 117, 115, 72, 101, 97, 100];

  MirrorAudioCodec? _codec;
  bool _configured = false;

  List<FeedEvent> add(ScrcpyPacket packet) {
    return switch (packet) {
      CodecPacket(codecId: CodecPacket.opus) => _start(.opus),
      CodecPacket(codecId: CodecPacket.raw) => _start(.pcm),
      CodecPacket(codecId: CodecPacket.disabled) => const [
        FeedAudioUnavailable(.unsupported),
      ],
      CodecPacket() => const [FeedAudioUnavailable(.failed)],
      MediaPacket() => _media(packet),
      DeviceMetaPacket() || SessionPacket() => const [],
    };
  }

  /// Opus tells its channels in a config packet that comes first, so the
  /// config waits for it. Plain samples have none.
  List<FeedEvent> _start(MirrorAudioCodec codec) {
    _codec = codec;
    _configured = false;
    return const [];
  }

  List<FeedEvent> _media(MediaPacket packet) {
    final codec = _codec;
    if (codec == null) {
      return const [];
    }

    if (packet.isConfig) {
      return _configure(codec, channels: _channelsOf(packet.data));
    }

    return [
      if (!_configured) ..._configure(codec, channels: _stereo),
      FeedAudio(MirrorAudioPacket(data: packet.data, ptsUs: packet.ptsUs)),
    ];
  }

  List<FeedEvent> _configure(MirrorAudioCodec codec, {required int channels}) {
    _configured = true;
    return [
      FeedAudioConfigured(
        MirrorAudioConfig(
          codec: codec,
          sampleRate: _sampleRate,
          channels: channels,
        ),
      ),
    ];
  }

  int _channelsOf(Uint8List config) {
    if (config.length <= _opusHeadChannels) {
      return _stereo;
    }

    for (final (index, byte) in _opusHeadMagic.indexed) {
      if (config[index] != byte) {
        return _stereo;
      }
    }

    return config[_opusHeadChannels];
  }
}
