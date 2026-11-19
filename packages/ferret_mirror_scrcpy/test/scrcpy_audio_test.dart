import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bytes.dart';

class _FakeConnection implements AdbConnection {
  _FakeConnection(this.name);

  final String name;
  final StreamController<Uint8List> incoming = .new();
  final List<List<int>> sent = [];
  bool closed = false;

  @override
  Stream<Uint8List> get input => incoming.stream;

  @override
  void add(List<int> bytes) => sent.add(bytes);

  @override
  void close() => closed = true;
}

void main() {
  group('ScrcpyDemuxer on the audio socket', () {
    test('reads what a real server sends first', () {
      final packets = ScrcpyDemuxer.audio().add(emulatorAudioStart);

      expect(packets, hasLength(4));
      expect((packets[0] as CodecPacket).codecId, CodecPacket.opus);

      final config = packets[1] as MediaPacket;
      expect(config.isConfig, isTrue);
      expect(config.data, hasLength(19));
      expect(String.fromCharCodes(config.data.sublist(0, 8)), 'OpusHead');

      final silence = packets[2] as MediaPacket;
      expect(silence.isConfig, isFalse);
      expect(silence.ptsUs, 0x05228c3634);
      expect(silence.data, [0xfc, 0xff, 0xfe]);
      expect((packets[3] as MediaPacket).data, [0xfc, 0xff, 0xfe]);
    });

    test('gives the same packets whatever the chunk sizes', () {
      final demuxer = ScrcpyDemuxer.audio();
      final packets = [
        for (final byte in joined([emulatorAudioStart, emulatorTonePacket]))
          ...demuxer.add([byte]),
      ];

      expect(packets, hasLength(5));
      final tone = packets[4] as MediaPacket;
      expect(tone.data, hasLength(334));
      expect(tone.ptsUs, 0x05229a4897);
      expect(
        OpusPacket.durationOf(tone.data),
        const Duration(milliseconds: 20),
      );
    });

    test('reads plain samples too', () {
      final demuxer = ScrcpyDemuxer.audio();
      final samples = List.filled(4096, 1);

      final packets = demuxer.add(joined([emulatorRawAudioStart, samples]));

      expect((packets[0] as CodecPacket).codecId, CodecPacket.raw);
      final first = packets[1] as MediaPacket;
      expect(first.data, samples);
      expect(first.ptsUs, 0x05242ac53c);
    });
  });

  group('AudioFeedAssembler', () {
    List<FeedEvent> eventsOf(List<int> bytes) {
      final assembler = AudioFeedAssembler();
      return [
        for (final packet in ScrcpyDemuxer.audio().add(bytes))
          ...assembler.add(packet),
      ];
    }

    test('configures from the Opus header, then hands over packets', () {
      final events = eventsOf(joined([emulatorAudioStart, emulatorTonePacket]));

      expect(events, hasLength(4));
      final config = (events[0] as FeedAudioConfigured).config;
      expect(config, const MirrorAudioConfig(codec: .opus));
      expect((events[1] as FeedAudio).packet.data, [0xfc, 0xff, 0xfe]);
      final tone = (events[3] as FeedAudio).packet;
      expect(tone.data, hasLength(334));
      expect(tone.ptsUs, 0x05229a4897);
    });

    test('reads a mono stream from its header', () {
      final mono = Uint8List.fromList(emulatorAudioStart)..[16 + 9] = 1;

      final config = (eventsOf(mono).first as FeedAudioConfigured).config;

      expect(config.channels, 1);
    });

    test('configures plain samples with their first packet', () {
      final events = eventsOf(
        joined([emulatorRawAudioStart, List.filled(4096, 0)]),
      );

      expect(
        (events[0] as FeedAudioConfigured).config,
        const MirrorAudioConfig(codec: .pcm),
      );
      expect((events[1] as FeedAudio).packet.data, hasLength(4096));
    });

    test('says when the device cannot capture its sound', () {
      final tooOld = eventsOf(const [0, 0, 0, 0]);
      final broken = eventsOf(const [0, 0, 0, 1]);
      final unknown = eventsOf(hex('666c6163'));

      expect(
        (tooOld.single as FeedAudioUnavailable).reason,
        AudioUnavailable.unsupported,
      );
      expect(
        (broken.single as FeedAudioUnavailable).reason,
        AudioUnavailable.failed,
      );
      expect(
        (unknown.single as FeedAudioUnavailable).reason,
        AudioUnavailable.failed,
      );
    });
  });

  group('ScrcpySockets', () {
    Future<ScrcpySockets?> connect(
      List<_FakeConnection> dialed, {
      required bool audio,
    }) {
      var count = 0;
      return ScrcpySockets.connect(
        () async {
          final connection = _FakeConnection(
            ['video', 'second', 'third'][count],
          );
          count++;
          dialed.add(connection);
          if (connection.name == 'video') {
            connection.incoming.add(Uint8List.fromList([0]));
          }

          return connection;
        },
        shouldGiveUp: () => false,
        audio: audio,
      );
    }

    test('opens video, audio, then control when sound is asked for', () async {
      final dialed = <_FakeConnection>[];

      final sockets = await connect(dialed, audio: true);
      final heard = <int>[];
      sockets?.audio?.listen(heard.addAll);
      dialed[1].incoming.add(Uint8List.fromList([1, 2, 3]));
      sockets?.sendControl(Uint8List.fromList([9]));
      await Future<void>.delayed(Duration.zero);

      expect(dialed, hasLength(3));
      expect(heard, [1, 2, 3]);
      expect(dialed[2].sent, [
        [9],
      ]);

      sockets?.close();
      expect(dialed.every((connection) => connection.closed), isTrue);
    });

    test('opens no audio socket for pictures only', () async {
      final dialed = <_FakeConnection>[];

      final sockets = await connect(dialed, audio: false);
      sockets?.sendControl(Uint8List.fromList([9]));

      expect(dialed, hasLength(2));
      expect(sockets?.audio, isNull);
      expect(dialed[1].sent, [
        [9],
      ]);
    });
  });
}
