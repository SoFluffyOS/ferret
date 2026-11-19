import 'dart:async';

import 'package:ferret_mirroring/src/audio/audio_sink.dart';
import 'package:ferret_mirroring/src/messages.g.dart';
import 'package:ferret_mirroring/src/stream/mirror_audio.dart';

/// macOS: Opus decoded by AudioToolbox, played through AVAudioEngine.
class NativeAudioSink implements AudioSink {
  NativeAudioSink({MirrorAudioHostApi? api})
    : _api = api ?? MirrorAudioHostApi();

  final MirrorAudioHostApi _api;

  bool _ready = false;

  @override
  Future<void> configure(
    MirrorAudioConfig config, {
    bool silent = false,
  }) async {
    _ready = false;
    await _api.configure(
      switch (config.codec) {
        .opus => .opus,
        .pcm => .pcm,
      },
      config.sampleRate,
      config.channels,
      silent,
    );
    _ready = true;
  }

  @override
  void play(MirrorAudioPacket packet) {
    if (!_ready) {
      return;
    }

    unawaited(_api.play(packet.data).catchError((Object _) {}));
  }

  @override
  void flush() {
    if (!_ready) {
      return;
    }

    unawaited(_api.flush().catchError((Object _) {}));
  }

  @override
  void setVolume(double volume) =>
      unawaited(_api.setVolume(volume).catchError((Object _) {}));

  @override
  Future<AudioSinkStats> stats() async {
    final stats = await _api.stats();
    return AudioSinkStats(frames: stats.frames, peak: stats.peak);
  }

  @override
  Future<void> dispose() async {
    _ready = false;
    await _api.close().catchError((Object _) {});
  }
}
