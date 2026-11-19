import 'dart:io';
import 'dart:typed_data';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_audio_sink.dart';

class FakeAudioApi implements MirrorAudioHostApi {
  final List<String> calls = [];
  bool refuse = false;

  @override
  Future<void> configure(
    NativeAudioCodec codec,
    int sampleRate,
    int channels,
    bool silent,
  ) async {
    if (refuse) {
      throw StateError('no_sound');
    }

    calls.add('configure ${codec.name} $sampleRate $channels $silent');
  }

  @override
  Future<void> play(Uint8List data) async => calls.add('play ${data.length}');

  @override
  Future<void> flush() async => calls.add('flush');

  @override
  Future<void> setVolume(double volume) async => calls.add('volume $volume');

  @override
  Future<NativeAudioStats> stats() async =>
      NativeAudioStats(frames: 960, peak: 0.5);

  @override
  Future<void> close() async => calls.add('close');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A 20 ms stereo CELT packet: only its first byte is read here.
MirrorAudioPacket opus(int index) => MirrorAudioPacket(
  data: Uint8List.fromList([0xFC, 0, 0]),
  ptsUs: index * 20000,
);

void main() {
  group('OpusPacket', () {
    test('reads how long a packet plays from its first bytes', () {
      expect(OpusPacket.samplesOf(Uint8List.fromList([0xFC])), 960);
      expect(OpusPacket.samplesOf(Uint8List.fromList([0xFD])), 1920);
      expect(OpusPacket.samplesOf(Uint8List.fromList([0xF0])), 480);
      expect(OpusPacket.samplesOf(Uint8List.fromList([0x18])), 2880);
      expect(OpusPacket.samplesOf(Uint8List.fromList([0x68])), 960);
      expect(OpusPacket.samplesOf(Uint8List.fromList([0xFF, 0x03])), 2880);
      expect(
        OpusPacket.durationOf(Uint8List.fromList([0xFC])),
        const Duration(milliseconds: 20),
      );
    });

    test('nothing for what cannot be a packet', () {
      expect(OpusPacket.samplesOf(Uint8List(0)), 0);
      expect(OpusPacket.samplesOf(Uint8List.fromList([0xFF])), 0);
    });
  });

  group('PcmSamples', () {
    final samples = Uint8List.fromList([0x00, 0x40, 0x00, 0xC0]);

    test('scales every sample', () {
      final half = ByteData.sublistView(PcmSamples.scaled(samples, 0.5));

      expect(half.getInt16(0, Endian.little), 8192);
      expect(half.getInt16(2, Endian.little), -8192);
      expect(PcmSamples.scaled(samples, 1), same(samples));
    });

    test('finds the loudest sample', () {
      expect(PcmSamples.peakOf(samples), 0.5);
      expect(PcmSamples.peakOf(Uint8List(8)), 0);
    });

    test('knows how long bytes play for', () {
      expect(
        PcmSamples.durationOf(3840, sampleRate: 48000, channels: 2),
        const Duration(milliseconds: 20),
      );
    });
  });

  group('AudioPlayout', () {
    late DateTime now;
    late FakeAudioSink sink;
    late AudioPlayout playout;

    setUp(() {
      now = DateTime(2026, 11, 19, 10);
      sink = FakeAudioSink();
      playout = AudioPlayout(sink: sink, clock: () => now);
    });

    test('plays packets once enough of them wait', () async {
      expect(
        await playout.configure(const MirrorAudioConfig(codec: .opus)),
        isTrue,
      );
      for (var index = 0; index < 5; index++) {
        playout.add(opus(index));
      }

      expect(sink.calls, [
        'configure opus',
        'play 0',
        'play 20000',
        'play 40000',
        'play 60000',
        'play 80000',
      ]);
      expect(playout.level, const Duration(milliseconds: 100));
    });

    test('measures plain samples by their size', () async {
      await playout.configure(const MirrorAudioConfig(codec: .pcm));
      playout.add(MirrorAudioPacket(data: Uint8List(3840 * 4), ptsUs: 0));

      expect(sink.calls, ['configure pcm', 'play 0']);
    });

    test('drops packets before it is set up, and after it closed', () async {
      playout.add(opus(0));
      await playout.configure(const MirrorAudioConfig(codec: .opus));
      await playout.close();
      playout.add(opus(1));

      expect(sink.calls, ['configure opus', 'dispose']);
    });

    test('says when this computer cannot play the sound', () async {
      sink.refuse = true;

      expect(
        await playout.configure(const MirrorAudioConfig(codec: .opus)),
        isFalse,
      );
      playout.add(opus(0));
      expect(sink.calls, isEmpty);
    });

    test('empties the sink when the sound fell behind', () async {
      await playout.configure(const MirrorAudioConfig(codec: .opus));
      for (var index = 0; index < 13; index++) {
        playout.add(opus(index));
      }

      expect(sink.calls.where((call) => call == 'flush'), hasLength(1));
      expect(playout.dropped, 12);
    });

    test('keeps the speakers out of a silent check', () async {
      final silent = AudioPlayout(sink: sink, clock: () => now, silent: true);
      await silent.configure(const MirrorAudioConfig(codec: .opus));

      expect(sink.silent, isTrue);
    });
  });

  group('NativeAudioSink', () {
    test('hands the stream to the platform', () async {
      final api = FakeAudioApi();
      final sink = NativeAudioSink(api: api);

      sink.play(opus(0));
      await sink.configure(const MirrorAudioConfig(codec: .opus));
      sink
        ..play(opus(1))
        ..flush()
        ..setVolume(0.4);
      final stats = await sink.stats();
      await sink.dispose();
      sink.play(opus(2));
      await Future<void>.delayed(Duration.zero);

      expect(api.calls, [
        'configure opus 48000 2 false',
        'play 3',
        'flush',
        'volume 0.4',
        'close',
      ]);
      expect(stats.frames, 960);
      expect(stats.peak, 0.5);
    });

    test('passes a refusal on', () async {
      final sink = NativeAudioSink(api: FakeAudioApi()..refuse = true);

      await expectLater(
        sink.configure(const MirrorAudioConfig(codec: .pcm)),
        throwsStateError,
      );
    });
  });

  group('ProcessAudioSink', () {
    late Directory folder;

    setUp(() => folder = Directory.systemTemp.createTempSync('ferret_sound'));
    tearDown(() => folder.deleteSync(recursive: true));

    test('pipes scaled samples into the first player there is', () async {
      final played = File('${folder.path}/played.raw');
      final sink = ProcessAudioSink(
        commands: (_) => [
          const AudioPlayerCommand('ferret-no-such-player', []),
          AudioPlayerCommand('sh', ['-c', 'cat > "${played.path}"']),
        ],
      );

      await sink.configure(const MirrorAudioConfig(codec: .pcm));
      sink
        ..setVolume(0.5)
        ..play(
          MirrorAudioPacket(
            data: Uint8List.fromList([0x00, 0x40, 0x00, 0xC0]),
            ptsUs: 0,
          ),
        );
      final stats = await sink.stats();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await sink.dispose();

      expect(stats.frames, 1);
      expect(stats.peak, 0.5);
      expect(played.readAsBytesSync(), [0x00, 0x20, 0x00, 0xE0]);
    });

    test('refuses Opus, and a computer without a player', () async {
      final sink = ProcessAudioSink(
        commands: (_) => const [
          AudioPlayerCommand('ferret-no-such-player', []),
        ],
      );

      await expectLater(
        sink.configure(const MirrorAudioConfig(codec: .opus)),
        throwsUnsupportedError,
      );
      await expectLater(
        sink.configure(const MirrorAudioConfig(codec: .pcm)),
        throwsStateError,
      );
    });

    test('a silent check starts no player', () async {
      final sink = ProcessAudioSink(
        commands: (_) => const [
          AudioPlayerCommand('ferret-no-such-player', []),
        ],
      );

      await sink.configure(const MirrorAudioConfig(codec: .pcm), silent: true);
      sink.play(MirrorAudioPacket(data: Uint8List(3840), ptsUs: 0));

      expect((await sink.stats()).frames, 960);
    });
  });
}
