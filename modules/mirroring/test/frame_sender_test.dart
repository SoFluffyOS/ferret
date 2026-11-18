import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protocol/mirroring.dart';

import 'helpers/fakes.dart';

MirrorFrame frame({bool keyframe = false, int bytes = 100, int ptsUs = 0}) =>
    MirrorFrame(data: Uint8List(bytes), ptsUs: ptsUs, keyframe: keyframe);

void main() {
  late List<Frame> sent;
  late List<Completer<void>> gates;
  late int keyframeRequests;
  late bool blocked;

  FrameSender sender({
    int maxPendingFrames = 3,
    int maxPendingBytes = 1 << 20,
  }) => FrameSender(
    send: (frame) {
      sent.add(frame);
      if (!blocked) {
        return Future.value();
      }

      final gate = Completer<void>();
      gates.add(gate);
      return gate.future;
    },
    requestKeyframe: () => keyframeRequests++,
    maxPendingFrames: maxPendingFrames,
    maxPendingBytes: maxPendingBytes,
  );

  Future<void> drain() async {
    for (final gate in gates) {
      gate.complete();
    }

    gates.clear();
    await settle();
  }

  setUp(() {
    sent = [];
    gates = [];
    keyframeRequests = 0;
    blocked = false;
  });

  test('frames carry the config, a rising sequence, pts and the keyframe '
      'flag', () async {
    final frames = sender()..startConfig(3);

    frames
      ..offer(
        MirrorFrame(
          data: Uint8List.fromList([0, 0, 0, 1, 0x65]),
          ptsUs: 1000,
          keyframe: true,
        ),
      )
      ..offer(frame(ptsUs: 17666));
    await settle();

    expect(sent, hasLength(2));
    expect(sent.first.configId, 3);
    expect(sent.first.sequence.toInt(), 0);
    expect(sent.first.ptsUs.toInt(), 1000);
    expect(sent.first.keyframe, isTrue);
    expect(sent.first.data, [0, 0, 0, 1, 0x65]);
    expect(sent.last.sequence.toInt(), 1);
    expect(sent.last.keyframe, isFalse);

    final wire = Frame.fromBuffer(sent.first.writeToBuffer());
    expect(wire.ptsUs.toInt(), 1000);
    expect(wire.data, sent.first.data);
  });

  test('a new config starts with a keyframe: frames before it are '
      'dropped', () async {
    final frames = sender()..startConfig(1);

    expect(frames.offer(frame()), isFalse);
    expect(frames.offer(frame(keyframe: true)), isTrue);
    expect(frames.offer(frame()), isTrue);
    await settle();

    expect(sent.map((frame) => frame.sequence.toInt()), [1, 2]);
    expect(keyframeRequests, 0);
  });

  test('when the connection backs up, frames are dropped until a keyframe, '
      'which is asked for once it clears', () async {
    final frames = sender()..startConfig(1);
    blocked = true;

    frames
      ..offer(frame(keyframe: true))
      ..offer(frame())
      ..offer(frame());
    expect(frames.isBackedUp, isTrue);

    expect(frames.offer(frame()), isFalse);
    expect(frames.offer(frame()), isFalse);
    expect(frames.isWaitingForKeyframe, isTrue);
    expect(keyframeRequests, 0, reason: 'no room for a keyframe yet');

    await drain();
    expect(frames.pendingFrames, 0);
    expect(keyframeRequests, 1);

    expect(frames.offer(frame()), isFalse, reason: 'still not a keyframe');
    expect(keyframeRequests, 1, reason: 'asked once per gap');

    expect(frames.offer(frame(keyframe: true)), isTrue);
    expect(frames.offer(frame()), isTrue);
    expect(frames.isWaitingForKeyframe, isFalse);
    expect(sent.map((frame) => frame.sequence.toInt()), [0, 1, 2, 6, 7]);
  });

  test('bytes on their way count too', () async {
    final frames = sender(maxPendingFrames: 100, maxPendingBytes: 250)
      ..startConfig(1);
    blocked = true;

    expect(frames.offer(frame(keyframe: true, bytes: 200)), isTrue);
    expect(frames.offer(frame(bytes: 100)), isTrue);
    expect(frames.offer(frame(bytes: 10)), isFalse);
  });

  test('a keyframe still goes out into a short queue, but not into a long '
      'one', () async {
    final frames = sender(maxPendingFrames: 1)..startConfig(1);
    blocked = true;

    expect(frames.offer(frame(keyframe: true)), isTrue);
    expect(frames.offer(frame(keyframe: true)), isTrue);
    expect(frames.offer(frame(keyframe: true)), isFalse);

    await drain();
    expect(keyframeRequests, 1, reason: 'the dropped keyframe is asked again');
  });

  test('a failed send drops to the next keyframe', () async {
    final frames = FrameSender(
      send: (_) => Future.error(StateError('closed')),
      requestKeyframe: () => keyframeRequests++,
    )..startConfig(1);

    frames.offer(frame(keyframe: true));
    await settle();

    expect(frames.isWaitingForKeyframe, isTrue);
    expect(frames.pendingFrames, 0);
    expect(keyframeRequests, 1);
  });

  test('counts are taken once per window', () async {
    final frames = sender()..startConfig(1);

    frames
      ..offer(frame())
      ..offer(frame(keyframe: true))
      ..offer(frame());

    expect(frames.takeCounts(), (sent: 2, dropped: 1));
    expect(frames.takeCounts(), (sent: 0, dropped: 0));
  });

  group('bitrate', () {
    test('drops fast when frames were dropped, down to the floor', () {
      final bitrate = BitrateController(min: 2000, max: 8000, start: 4000);

      expect(bitrate.onWindow(congested: true), 2800);
      expect(bitrate.onWindow(congested: true), 2000);
      expect(bitrate.onWindow(congested: true), isNull);
      expect(bitrate.bitrate, 2000);
    });

    test('rises slowly after calm seconds, up to the ceiling', () {
      final bitrate = BitrateController(
        min: 2000,
        max: 5000,
        start: 4000,
        calmWindowsToRaise: 3,
      );

      expect(bitrate.onWindow(congested: false), isNull);
      expect(bitrate.onWindow(congested: false), isNull);
      expect(bitrate.onWindow(congested: false), 4800);
      bitrate
        ..onWindow(congested: false)
        ..onWindow(congested: false);
      expect(bitrate.onWindow(congested: false), 5000);
      bitrate
        ..onWindow(congested: false)
        ..onWindow(congested: false);
      expect(bitrate.onWindow(congested: false), isNull);
    });

    test('a drop resets the calm count', () {
      final bitrate = BitrateController(calmWindowsToRaise: 2)
        ..onWindow(congested: false)
        ..onWindow(congested: true);

      expect(bitrate.onWindow(congested: false), isNull);
      expect(bitrate.onWindow(congested: false), isNotNull);
    });
  });

  group('protocol', () {
    test('the source picks the viewer\'s first codec it can encode', () {
      const viewer = [Codec.CODEC_H264, Codec.CODEC_JPEG];

      expect(MirrorProtocol.pick(viewer, (_) => true), MirrorCodec.h264);
      expect(
        MirrorProtocol.pick(viewer, (codec) => codec == .jpeg),
        MirrorCodec.jpeg,
      );
      expect(
        MirrorProtocol.pick(const [.CODEC_JPEG], (_) => true),
        MirrorCodec.jpeg,
      );
      expect(MirrorProtocol.pick(viewer, (_) => false), isNull);
      expect(MirrorProtocol.pick(const [], (_) => true), isNull);
    });

    test('frame rate and size stay inside the limits', () {
      expect(MirrorProtocol.fpsFor(.h264, 0), 60);
      expect(MirrorProtocol.fpsFor(.h264, 15), 30);
      expect(MirrorProtocol.fpsFor(.h264, 120), 60);
      expect(MirrorProtocol.fpsFor(.jpeg, 60), 10);
      expect(MirrorProtocol.sideFor(0, 1920), 1920);
      expect(MirrorProtocol.sideFor(4000, 1920), 1920);
      expect(MirrorProtocol.sideFor(1280, 1920), 1280);
    });

    test('a stream config survives the wire with its parameter sets', () {
      final config = StreamConfig(
        configId: 2,
        codec: .CODEC_H264,
        width: 1080,
        height: 2400,
        rotation: 90,
        fps: 60,
        sps: [0x67, 0x42, 0xc0, 0x2a],
        pps: [0x68, 0xce, 0x3c, 0x80],
      );

      final wire = StreamConfig.fromBuffer(config.writeToBuffer());

      expect(wire.configId, 2);
      expect(MirrorProtocol.fromProto(wire.codec), MirrorCodec.h264);
      expect(
        (wire.width, wire.height, wire.rotation, wire.fps),
        (
          1080,
          2400,
          90,
          60,
        ),
      );
      expect(wire.sps, [0x67, 0x42, 0xc0, 0x2a]);
      expect(wire.pps, [0x68, 0xce, 0x3c, 0x80]);
    });
  });
}
