import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ferret_mirroring/src/audio/audio_sink.dart';
import 'package:ferret_mirroring/src/audio/pcm_samples.dart';
import 'package:ferret_mirroring/src/stream/mirror_audio.dart';

/// A program that plays raw samples from its standard input.
class AudioPlayerCommand {
  const AudioPlayerCommand(this.executable, this.arguments);

  /// PulseAudio's player, which PipeWire's PulseAudio server takes too.
  factory AudioPlayerCommand.pacat(MirrorAudioConfig config) =>
      AudioPlayerCommand('pacat', [
        '--playback',
        '--raw',
        '--format=s16le',
        '--rate=${config.sampleRate}',
        '--channels=${config.channels}',
        '--latency-msec=40',
        '--client-name=Ferret',
        '--stream-name=Screen sound',
      ]);

  /// ALSA's player, for a computer without a sound server.
  factory AudioPlayerCommand.aplay(MirrorAudioConfig config) =>
      AudioPlayerCommand('aplay', [
        '--quiet',
        '--file-type=raw',
        '--format=S16_LE',
        '--rate=${config.sampleRate}',
        '--channels=${config.channels}',
        '--buffer-time=40000',
        '-',
      ]);

  final String executable;
  final List<String> arguments;
}

/// Linux: plain samples piped into the sound server's own player
/// (`pacat`, else `aplay`), so no library has to be built in. Opus isn't
/// decoded here.
class ProcessAudioSink implements AudioSink {
  ProcessAudioSink({
    List<AudioPlayerCommand> Function(MirrorAudioConfig config)? commands,
  }) : _commands = commands ?? _linuxCommands;

  final List<AudioPlayerCommand> Function(MirrorAudioConfig config) _commands;

  Process? _player;
  AudioPlayerCommand? _command;
  MirrorAudioConfig? _config;
  bool _silent = false;
  double _volume = 1;
  int _frames = 0;
  double _peak = 0;

  @override
  Future<void> configure(
    MirrorAudioConfig config, {
    bool silent = false,
  }) async {
    if (config.codec != .pcm) {
      throw UnsupportedError('Only plain samples can be played here');
    }

    await _stopPlayer();
    _config = config;
    _silent = silent;
    _frames = 0;
    _peak = 0;
    if (silent) {
      return;
    }

    for (final command in _commands(config)) {
      if (await _start(command)) {
        return;
      }
    }

    throw StateError('No program to play sound with was found');
  }

  @override
  void play(MirrorAudioPacket packet) {
    final config = _config;
    if (config == null) {
      return;
    }

    _frames +=
        packet.data.length ~/ (PcmSamples.bytesPerSample * config.channels);
    _peak = max(_peak, PcmSamples.peakOf(packet.data));
    final player = _player;
    if (_silent || player == null) {
      return;
    }

    try {
      player.stdin.add(PcmSamples.scaled(packet.data, _volume));
    } on StateError {
      _player = null;
    }
  }

  /// A pipe can't be emptied, so the player is started again.
  @override
  void flush() {
    final command = _command;
    if (_player == null || command == null) {
      return;
    }

    unawaited(_stopPlayer().then((_) => _start(command)));
  }

  @override
  void setVolume(double volume) => _volume = volume.clamp(0, 1).toDouble();

  @override
  Future<AudioSinkStats> stats() async =>
      AudioSinkStats(frames: _frames, peak: _peak);

  @override
  Future<void> dispose() async {
    _config = null;
    await _stopPlayer();
  }

  Future<bool> _start(AudioPlayerCommand command) async {
    try {
      final player = await Process.start(
        command.executable,
        command.arguments,
      );
      // A player that ends early leaves a closed pipe behind: writing to
      // it must not bring the app down.
      unawaited(player.stdin.done.catchError((Object _) {}));
      unawaited(player.stdout.drain<void>().catchError((Object _) {}));
      unawaited(player.stderr.drain<void>().catchError((Object _) {}));
      unawaited(
        player.exitCode.then((_) {
          if (identical(_player, player)) {
            _player = null;
          }
        }),
      );
      _player = player;
      _command = command;
      return true;
    } on ProcessException {
      return false;
    }
  }

  Future<void> _stopPlayer() async {
    final player = _player;
    _player = null;
    if (player == null) {
      return;
    }

    player.kill();
    await player.exitCode;
  }

  static List<AudioPlayerCommand> _linuxCommands(MirrorAudioConfig config) => [
    .pacat(config),
    .aplay(config),
  ];
}
