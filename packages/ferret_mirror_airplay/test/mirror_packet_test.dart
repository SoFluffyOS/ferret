import 'dart:typed_data';

import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mirror_packets.dart';

void main() {
  group('MirrorPacketHeader', () {
    test('reads the size, type and timestamp of a video packet', () {
      final header = MirrorPacketHeader.parse(
        mirrorPacket(
          type: 0,
          payload: List.filled(300, 0),
          // 12 seconds and a half, as NTP seconds and fraction.
          timestamp: (12 << 32) | 0x80000000,
        ),
      );

      expect(header.type, MirrorPayloadType.video);
      expect(header.payloadSize, 300);
      expect(header.timestampUs, 12500000);
    });

    test('reads the picture and screen sizes of a codec packet', () {
      final header = MirrorPacketHeader.parse(
        mirrorPacket(
          type: 1,
          payload: avccRecord(),
          option: 0x0116,
          width: 886,
          height: 1920,
          sourceWidth: 1170,
          sourceHeight: 2532,
        ),
      );

      expect(header.type, MirrorPayloadType.codec);
      expect(header.option, 0x0116);
      expect((header.width, header.height), (886, 1920));
      expect((header.sourceWidth, header.sourceHeight), (1170, 2532));
    });

    test('names heartbeats and leaves the rest as other', () {
      MirrorPayloadType typeOf(int type) => MirrorPacketHeader.parse(
        mirrorPacket(type: type, payload: const []),
      ).type;

      expect(typeOf(2), MirrorPayloadType.heartbeat);
      expect(typeOf(5), MirrorPayloadType.other);
    });

    test('takes sizes that are not numbers as unknown', () {
      final bytes = mirrorPacket(type: 1, payload: const []);
      ByteData.sublistView(bytes).setFloat32(56, double.nan, Endian.little);

      expect(MirrorPacketHeader.parse(bytes).width, 0);
    });

    test('refuses fewer than 128 bytes', () {
      expect(
        () => MirrorPacketHeader.parse(Uint8List(127)),
        throwsFormatException,
      );
    });
  });

  group('MirrorPacketReader', () {
    final first = mirrorPacket(type: 1, payload: avccRecord(), timestamp: 7);
    final second = mirrorPacket(
      type: 0,
      payload: List.generate(500, (i) => i & 0xff),
    );
    final third = mirrorPacket(type: 2, payload: const []);
    final all = Uint8List.fromList([...first, ...second, ...third]);

    void expectAll(List<MirrorPacket> packets) {
      expect(packets.map((packet) => packet.header.type), [
        MirrorPayloadType.codec,
        MirrorPayloadType.video,
        MirrorPayloadType.heartbeat,
      ]);
      expect(packets[0].payload, avccRecord());
      expect(packets[0].header.timestamp, 7);
      expect(packets[1].payload, List.generate(500, (i) => i & 0xff));
      expect(packets[2].payload, isEmpty);
    }

    test('reads packets that arrive in one piece', () {
      expectAll(MirrorPacketReader().add(all));
    });

    test('reads the same packets however the bytes are cut', () {
      for (final step in const [1, 7, 127, 128, 129, 400]) {
        final reader = MirrorPacketReader();
        final packets = <MirrorPacket>[];
        for (var offset = 0; offset < all.length; offset += step) {
          final end = (offset + step).clamp(0, all.length);
          packets.addAll(reader.add(all.sublist(offset, end)));
        }

        expectAll(packets);
      }
    });

    test('refuses a payload larger than any picture', () {
      final header = mirrorPacket(type: 0, payload: const []);
      ByteData.sublistView(header).setUint32(
        0,
        MirrorPacketReader.maxPayload + 1,
        Endian.little,
      );

      expect(() => MirrorPacketReader().add(header), throwsFormatException);
    });
  });
}
