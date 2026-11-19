import 'package:ferret_mirroring/ferret_mirroring.dart';

/// Remembers what it was asked to play.
class FakeAudioSink implements AudioSink {
  final List<String> calls = [];
  bool refuse = false;
  bool? silent;
  double volume = 1;

  @override
  Future<void> configure(
    MirrorAudioConfig config, {
    bool silent = false,
  }) async {
    if (refuse) {
      throw StateError('no output');
    }

    this.silent = silent;
    calls.add('configure ${config.codec.name}');
  }

  @override
  void play(MirrorAudioPacket packet) => calls.add('play ${packet.ptsUs}');

  @override
  void flush() => calls.add('flush');

  @override
  void setVolume(double volume) => this.volume = volume;

  @override
  Future<AudioSinkStats> stats() async => const AudioSinkStats();

  @override
  Future<void> dispose() async => calls.add('dispose');
}
