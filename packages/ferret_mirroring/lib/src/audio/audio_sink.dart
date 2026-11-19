import 'dart:io';

import 'package:ferret_mirroring/src/audio/native_audio_sink.dart';
import 'package:ferret_mirroring/src/audio/no_audio_sink.dart';
import 'package:ferret_mirroring/src/audio/process_audio_sink.dart';
import 'package:ferret_mirroring/src/audio/wave_out_audio_sink.dart';
import 'package:ferret_mirroring/src/stream/mirror_audio.dart';

/// Plays a mirrored device's sound on this computer: every packet it is
/// given, back to back, as soon as it can. Pacing is not its job; see
/// `AudioPlayout`.
abstract interface class AudioSink {
  /// The sink for this platform: AVAudioEngine on macOS, PulseAudio's or
  /// ALSA's own player on Linux, waveOut on Windows.
  static AudioSink current() {
    if (Platform.isMacOS) {
      return NativeAudioSink();
    }

    if (Platform.isLinux) {
      return ProcessAudioSink();
    }

    if (Platform.isWindows) {
      return WaveOutAudioSink();
    }

    return const NoAudioSink();
  }

  /// What [current] can play here, best first. Only macOS has an Opus
  /// decoder at hand; the others take plain samples.
  static List<MirrorAudioCodec> get platformCodecs {
    if (Platform.isMacOS) {
      return const [.opus, .pcm];
    }

    if (Platform.isLinux || Platform.isWindows) {
      return const [.pcm];
    }

    return const [];
  }

  /// Gets ready for [config]. With [silent], sound is decoded and
  /// measured but never reaches a speaker. Throws when it can't be played
  /// here.
  Future<void> configure(MirrorAudioConfig config, {bool silent = false});

  void play(MirrorAudioPacket packet);

  /// Throws away what was handed over and hasn't played yet.
  void flush();

  /// From 0 (silent) to 1 (as loud as it was captured).
  void setVolume(double volume);

  Future<AudioSinkStats> stats();

  Future<void> dispose();
}

/// What a sink did with the sound it was given, since it was configured.
class AudioSinkStats {
  const AudioSinkStats({this.frames = 0, this.peak = 0});

  /// Samples per channel that came out of the decoder.
  final int frames;

  /// The loudest sample so far, from 0 to 1. 0 means pure silence.
  final double peak;
}
