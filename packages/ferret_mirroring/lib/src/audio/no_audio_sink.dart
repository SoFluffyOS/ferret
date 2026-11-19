import 'package:ferret_mirroring/src/audio/audio_sink.dart';
import 'package:ferret_mirroring/src/stream/mirror_audio.dart';

/// Where nothing can play a mirrored device's sound.
class NoAudioSink implements AudioSink {
  const NoAudioSink();

  @override
  Future<void> configure(
    MirrorAudioConfig config, {
    bool silent = false,
  }) async {
    throw UnsupportedError('No sound output on this platform');
  }

  @override
  void play(MirrorAudioPacket packet) {}

  @override
  void flush() {}

  @override
  void setVolume(double volume) {}

  @override
  Future<AudioSinkStats> stats() async => const AudioSinkStats();

  @override
  Future<void> dispose() async {}
}
