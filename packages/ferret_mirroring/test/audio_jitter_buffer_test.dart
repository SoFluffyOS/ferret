import 'dart:typed_data';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

const packetTime = Duration(milliseconds: 20);

MirrorAudioPacket packet(int index) => MirrorAudioPacket(
  data: Uint8List(4),
  ptsUs: index * packetTime.inMicroseconds,
);

void main() {
  late DateTime now;
  late AudioJitterBuffer buffer;

  setUp(() {
    now = DateTime(2026, 11, 19, 10);
    buffer = AudioJitterBuffer(clock: () => now);
  });

  List<int> played(JitterVerdict verdict) => [
    for (final played in verdict.play)
      played.ptsUs ~/ packetTime.inMicroseconds,
  ];

  test('holds the first packets until the target is waiting', () {
    expect(buffer.add(packet(0), packetTime).play, isEmpty);
    expect(buffer.add(packet(1), packetTime).play, isEmpty);
    expect(buffer.add(packet(2), packetTime).play, isEmpty);
    expect(buffer.isPlaying, isFalse);
    expect(buffer.level, const Duration(milliseconds: 60));

    final verdict = buffer.add(packet(3), packetTime);

    expect(played(verdict), [0, 1, 2, 3]);
    expect(verdict.flush, isFalse);
    expect(buffer.isPlaying, isTrue);
    expect(buffer.level, const Duration(milliseconds: 80));
  });

  test('lets packets through as they come once it plays', () {
    for (var index = 0; index < 4; index++) {
      buffer.add(packet(index), packetTime);
    }

    now = now.add(packetTime);
    final verdict = buffer.add(packet(4), packetTime);

    expect(played(verdict), [4]);
    expect(buffer.level, const Duration(milliseconds: 80));
  });

  test('a burst within the limit is all played', () {
    for (var index = 0; index < 4; index++) {
      buffer.add(packet(index), packetTime);
    }

    final burst = [
      for (var index = 4; index < 10; index++)
        ...played(buffer.add(packet(index), packetTime)),
    ];

    expect(burst, [4, 5, 6, 7, 8, 9]);
    expect(buffer.dropped, 0);
    expect(buffer.level, const Duration(milliseconds: 200));
  });

  test('fills up again after the sink ran dry', () {
    for (var index = 0; index < 4; index++) {
      buffer.add(packet(index), packetTime);
    }

    now = now.add(const Duration(milliseconds: 300));
    expect(buffer.level, Duration.zero);
    expect(buffer.add(packet(20), packetTime).play, isEmpty);
    expect(buffer.underruns, 1);
    expect(buffer.isPlaying, isFalse);

    buffer.add(packet(21), packetTime);
    buffer.add(packet(22), packetTime);
    final verdict = buffer.add(packet(23), packetTime);

    expect(played(verdict), [20, 21, 22, 23]);
    expect(verdict.flush, isFalse);
  });

  test('drops the backlog when more than the limit waits', () {
    var flushes = 0;
    for (var index = 0; index < 13; index++) {
      final verdict = buffer.add(packet(index), packetTime);
      if (verdict.flush) {
        flushes++;
      }
    }

    expect(flushes, 1);
    expect(buffer.dropped, 12);
    expect(buffer.isPlaying, isFalse);
    expect(buffer.level, packetTime);

    buffer.add(packet(13), packetTime);
    buffer.add(packet(14), packetTime);
    final verdict = buffer.add(packet(15), packetTime);

    expect(played(verdict), [12, 13, 14, 15]);
    expect(buffer.level, const Duration(milliseconds: 80));
  });

  test('drops sound captured long before the picture shown now', () {
    final late = buffer.add(
      packet(0),
      packetTime,
      videoPtsUs: const Duration(milliseconds: 500).inMicroseconds,
    );
    final close = buffer.add(
      packet(1),
      packetTime,
      videoPtsUs: const Duration(milliseconds: 300).inMicroseconds,
    );

    expect(late.play, isEmpty);
    expect(buffer.dropped, 1);
    expect(close.play, isEmpty);
    expect(buffer.level, packetTime);
  });

  test('ignores a packet without a length', () {
    expect(buffer.add(packet(0), Duration.zero).play, isEmpty);
    expect(buffer.level, Duration.zero);
  });

  test('reset starts over', () {
    for (var index = 0; index < 4; index++) {
      buffer.add(packet(index), packetTime);
    }

    buffer.reset();

    expect(buffer.isPlaying, isFalse);
    expect(buffer.level, Duration.zero);
    expect(buffer.add(packet(0), packetTime).play, isEmpty);
  });
}
