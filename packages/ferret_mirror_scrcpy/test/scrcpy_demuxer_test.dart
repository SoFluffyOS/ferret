import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bytes.dart';

void main() {
  group('ScrcpyDemuxer', () {
    test('reads what a real server sends first', () {
      final packets = ScrcpyDemuxer().add(emulatorHandshake);

      expect(packets, hasLength(4));
      expect((packets[0] as DeviceMetaPacket).deviceName, 'sdk_gphone64_arm64');
      expect((packets[1] as CodecPacket).codecId, CodecPacket.h264);

      final session = packets[2] as SessionPacket;
      expect((session.width, session.height), (576, 1280));

      final config = packets[3] as MediaPacket;
      expect(config.isConfig, isTrue);
      expect(config.isKeyframe, isFalse);
      expect(config.ptsUs, 0);
      expect(config.data, hasLength(32));
    });

    test('gives the same packets whatever the chunk sizes', () {
      final demuxer = ScrcpyDemuxer();
      final packets = [
        for (final byte in emulatorHandshake) ...demuxer.add([byte]),
      ];

      expect(packets.map((packet) => packet.runtimeType), [
        DeviceMetaPacket,
        CodecPacket,
        SessionPacket,
        MediaPacket,
      ]);
    });

    test('reads the keyframe flag, the time and the size of pictures', () {
      final demuxer = ScrcpyDemuxer()..add(emulatorHandshake);
      final keyframe = List.filled(26693, 7);
      final delta = List.filled(180, 9);

      final packets = demuxer.add(
        joined([emulatorKeyframeHeader, keyframe, emulatorDeltaHeader, delta]),
      );

      final first = packets[0] as MediaPacket;
      expect(first.isKeyframe, isTrue);
      expect(first.isConfig, isFalse);
      expect(first.ptsUs, 0x1ec59420);
      expect(first.data, keyframe);

      final second = packets[1] as MediaPacket;
      expect(second.isKeyframe, isFalse);
      expect(second.ptsUs, 0x1ec71ac0);
      expect(second.data, delta);
    });

    test('keeps a picture back until all of it arrived', () {
      final demuxer = ScrcpyDemuxer()..add(emulatorHandshake);
      final header = mediaHeader(ptsUs: 40000, length: 6, isKeyframe: true);

      expect(
        demuxer.add(
          joined([
            header,
            [1, 2, 3],
          ]),
        ),
        isEmpty,
      );

      final packets = demuxer.add([4, 5, 6]);
      expect((packets.single as MediaPacket).data, [1, 2, 3, 4, 5, 6]);
    });

    test('reads a new session when the device rotates', () {
      final demuxer = ScrcpyDemuxer()..add(emulatorHandshake);

      final packets = demuxer.add(sessionHeader(1280, 576));

      final session = packets.single as SessionPacket;
      expect((session.width, session.height), (1280, 576));
    });

    test('expects no dummy byte when told so', () {
      final demuxer = ScrcpyDemuxer(expectDummyByte: false);

      final packets = demuxer.add(emulatorHandshake.sublist(1));

      expect(packets, hasLength(4));
    });

    test('refuses a picture too large to be one', () {
      final demuxer = ScrcpyDemuxer()..add(emulatorHandshake);
      final header = mediaHeader(
        ptsUs: 1,
        length: ScrcpyDemuxer.maxPacketLength + 1,
      );

      expect(() => demuxer.add(header), throwsFormatException);
    });
  });
}
