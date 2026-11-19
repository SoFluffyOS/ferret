import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:ferret_mirroring/src/audio/audio_sink.dart';
import 'package:ferret_mirroring/src/audio/pcm_samples.dart';
import 'package:ferret_mirroring/src/audio/win_mm.dart';
import 'package:ferret_mirroring/src/stream/mirror_audio.dart';
import 'package:ffi/ffi.dart';

/// Windows: plain samples handed to waveOut, the sound API every Windows
/// has, called straight from Dart. Opus isn't decoded here.
class WaveOutAudioSink implements AudioSink {
  WaveOutAudioSink({this.reclaimInterval = const Duration(milliseconds: 100)});

  /// How often buffers Windows is done with are given back.
  final Duration reclaimInterval;

  final List<Pointer<WaveHeader>> _queued = [];

  WinMm? _winMm;
  int _device = 0;
  MirrorAudioConfig? _config;
  Timer? _reclaim;
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

    _close();
    _config = config;
    _silent = silent;
    _frames = 0;
    _peak = 0;
    if (silent) {
      return;
    }

    final winMm = _winMm ??= WinMm.open();
    final format = calloc<WaveFormat>();
    final handle = calloc<IntPtr>();
    final blockAlign = config.channels * PcmSamples.bytesPerSample;
    format.ref
      ..formatTag = WinMm.pcmFormat
      ..channels = config.channels
      ..samplesPerSecond = config.sampleRate
      ..averageBytesPerSecond = config.sampleRate * blockAlign
      ..blockAlign = blockAlign
      ..bitsPerSample = PcmSamples.bytesPerSample * 8
      ..extraSize = 0;
    final result = winMm.open_(handle, WinMm.defaultDevice, format, 0, 0, 0);
    final device = handle.value;
    calloc
      ..free(format)
      ..free(handle);
    if (result != WinMm.noError) {
      throw StateError('Windows refused the sound output ($result)');
    }

    _device = device;
    _reclaim = Timer.periodic(reclaimInterval, (_) => _reclaimDone());
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
    final winMm = _winMm;
    if (_silent || winMm == null || _device == 0) {
      return;
    }

    _reclaimDone();
    final samples = PcmSamples.scaled(packet.data, _volume);
    final data = calloc<Uint8>(samples.length);
    data.asTypedList(samples.length).setAll(0, samples);
    final header = calloc<WaveHeader>();
    header.ref
      ..data = data
      ..bufferLength = samples.length;
    final prepared =
        winMm.prepareHeader(_device, header, sizeOf<WaveHeader>()) ==
        WinMm.noError;
    if (!prepared) {
      _free(header);
      return;
    }

    if (winMm.write(_device, header, sizeOf<WaveHeader>()) != WinMm.noError) {
      winMm.unprepareHeader(_device, header, sizeOf<WaveHeader>());
      _free(header);
      return;
    }

    _queued.add(header);
  }

  /// waveOutReset hands every waiting buffer back as done.
  @override
  void flush() {
    final winMm = _winMm;
    if (winMm == null || _device == 0) {
      return;
    }

    winMm.reset(_device);
    _reclaimDone();
  }

  @override
  void setVolume(double volume) => _volume = volume.clamp(0, 1).toDouble();

  @override
  Future<AudioSinkStats> stats() async =>
      AudioSinkStats(frames: _frames, peak: _peak);

  @override
  Future<void> dispose() async {
    _config = null;
    _close();
  }

  void _close() {
    _reclaim?.cancel();
    _reclaim = null;
    final winMm = _winMm;
    if (winMm == null || _device == 0) {
      return;
    }

    winMm.reset(_device);
    _reclaimDone();
    winMm.close(_device);
    _device = 0;
  }

  void _reclaimDone() {
    final winMm = _winMm;
    if (winMm == null || _device == 0) {
      return;
    }

    _queued.removeWhere((header) {
      if (header.ref.flags & WinMm.headerDone == 0) {
        return false;
      }

      winMm.unprepareHeader(_device, header, sizeOf<WaveHeader>());
      _free(header);
      return true;
    });
  }

  void _free(Pointer<WaveHeader> header) {
    calloc
      ..free(header.ref.data)
      ..free(header);
  }
}
