import 'dart:async';

import 'package:ferret_mirroring/src/audio/audio_jitter_buffer.dart';
import 'package:ferret_mirroring/src/audio/audio_sink.dart';
import 'package:ferret_mirroring/src/audio/opus_packet.dart';
import 'package:ferret_mirroring/src/audio/pcm_samples.dart';
import 'package:ferret_mirroring/src/stream/mirror_audio.dart';

/// Plays one feed's sound: sets the sink up for each config, paces the
/// packets through a jitter buffer, and keeps the sound from trailing the
/// picture.
class AudioPlayout {
  AudioPlayout({
    required AudioSink sink,
    required DateTime Function() clock,
    Duration target = const Duration(milliseconds: 80),
    Duration max = const Duration(milliseconds: 240),
    this.silent = false,
  }) : _sink = sink,
       _jitter = .new(clock: clock, target: target, max: max);

  /// Decode and measure, but keep the speakers out of it.
  final bool silent;

  final AudioSink _sink;
  final AudioJitterBuffer _jitter;

  MirrorAudioConfig? _config;
  int _configuration = 0;
  bool _closed = false;

  /// Packets thrown away to keep up, and times the sound ran dry.
  int get dropped => _jitter.dropped;
  int get underruns => _jitter.underruns;

  /// How much sound waits to be played.
  Duration get level => _jitter.level;

  /// Sets the sink up for [config]. False when this computer can't play
  /// it. Packets that arrive meanwhile are dropped.
  Future<bool> configure(MirrorAudioConfig config) async {
    final configuration = ++_configuration;
    _config = null;
    _jitter.reset();
    try {
      await _sink.configure(config, silent: silent);
    } on Object {
      return false;
    }

    if (_closed || configuration != _configuration) {
      return false;
    }

    _config = config;
    return true;
  }

  /// Takes the next packet. [videoPtsUs] is the time of the picture shown
  /// right now, when there is one.
  void add(MirrorAudioPacket packet, {int? videoPtsUs}) {
    final config = _config;
    if (_closed || config == null) {
      return;
    }

    final verdict = _jitter.add(
      packet,
      _durationOf(packet, config),
      videoPtsUs: videoPtsUs,
    );
    if (verdict.flush) {
      _sink.flush();
    }

    verdict.play.forEach(_sink.play);
  }

  void setVolume(double volume) => _sink.setVolume(volume);

  Future<AudioSinkStats> stats() => _sink.stats();

  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;
    _config = null;
    await _sink.dispose();
  }

  Duration _durationOf(MirrorAudioPacket packet, MirrorAudioConfig config) =>
      switch (config.codec) {
        .opus => OpusPacket.durationOf(packet.data),
        .pcm => PcmSamples.durationOf(
          packet.data.length,
          sampleRate: config.sampleRate,
          channels: config.channels,
        ),
      };
}
