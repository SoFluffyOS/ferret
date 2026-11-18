import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeHost host;
  late FakeSession pixel;
  late FakeDecoder decoder;
  late FerretRoute route;
  late MirrorRoutes routes;
  late MirrorViewer viewer;
  late DateTime now;
  late int decodersMade;
  late bool disposedInTest;

  StreamConfig config({int id = 1, Codec codec = .CODEC_H264}) => StreamConfig(
    configId: id,
    codec: codec,
    width: 1080,
    height: 2400,
    fps: 60,
    sps: [0x67],
    pps: [0x68],
  );

  Frame frame(int sequence, {bool keyframe = false, int configId = 1}) => Frame(
    configId: configId,
    sequence: Int64(sequence),
    ptsUs: Int64(sequence * 1000),
    keyframe: keyframe,
    data: [sequence],
  );

  Future<void> create({
    FakeDecoder? withDecoder,
    FutureOr<GeneratedMessage> Function(GeneratedMessage)? answer,
    List<MirrorCodec> codecs = const [.h264, .jpeg],
  }) async {
    host = await FakeHost.create();
    pixel = FakeSession(
      'pixel',
      answer: answer ?? (_) => StartPending(timeoutSeconds: 60),
    );
    host.sessions = [pixel];
    decoder = withDecoder ?? FakeDecoder();
    decodersMade = 0;
    disposedInTest = false;
    now = DateTime(2026, 11, 18, 21, 10);
    route = FerretRoute(
      host: host,
      featureId: MirroringFeature.featureId,
      clock: () => now,
    );
    routes = MirrorRoutes(
      ferret: route,
      settings: MirroringSettings(host.settings),
      receiverName: () => 'MacBook',
    );
    viewer = MirrorViewer(
      routes: routes,
      createDecoder: () {
        decodersMade++;
        return decoder;
      },
      codecs: codecs,
      settings: MirroringSettings(host.settings),
      clock: () => now,
    );
  }

  /// Request, consent on the phone, config and a first keyframe.
  Future<void> stream() async {
    await viewer.start('pixel');
    route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
    route.onConfig(pixel, config());
    await settle();
    route.onFrame(pixel, frame(0, keyframe: true));
    await settle();
  }

  setUp(create);

  tearDown(() async {
    if (!disposedInTest) {
      await viewer.dispose();
    }
  });

  /// A viewer made under fake time has to be let go under it too.
  void disposeIn(FakeAsync async) {
    viewer.dispose();
    async.flushMicrotasks();
    disposedInTest = true;
  }

  test('request, consent, streaming: the phases in order', () async {
    await viewer.start('pixel');
    final request = pixel.requests.single as StartRequest;
    expect(request.version, 1);
    expect(request.codecs, [Codec.CODEC_H264, Codec.CODEC_JPEG]);
    expect(viewer.current?.phase, ViewPhase.waitingForPhone);
    expect(decodersMade, 0, reason: 'no decoder before the yes');

    route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
    expect(viewer.current?.phase, ViewPhase.starting);
    expect(viewer.current?.startedAt, now);

    route.onConfig(pixel, config());
    await settle();
    expect(decoder.configs.single.width, 1080);
    expect(decoder.configs.single.sps, [0x67]);
    expect(viewer.current?.config?.codec, MirrorCodec.h264);

    route.onFrame(pixel, frame(0, keyframe: true));
    await settle();
    expect(viewer.current?.phase, ViewPhase.streaming);
    expect(viewer.picture.value?.width, 1080);
    expect(decoder.frames.single.keyframe, isTrue);
  });

  for (final (reason, end) in [
    (DenyReason.DENY_REASON_DENIED, ViewEnd.denied),
    (DenyReason.DENY_REASON_TIMEOUT, ViewEnd.timedOut),
    (DenyReason.DENY_REASON_BUSY, ViewEnd.busy),
    (DenyReason.DENY_REASON_UNSUPPORTED, ViewEnd.unsupported),
    (DenyReason.DENY_REASON_TURNED_OFF, ViewEnd.turnedOff),
    (DenyReason.DENY_REASON_VERSION, ViewEnd.version),
    (DenyReason.DENY_REASON_NO_CODEC, ViewEnd.noCodec),
    (DenyReason.DENY_REASON_CANNOT_ASK, ViewEnd.cannotAsk),
    (DenyReason.DENY_REASON_FAILED, ViewEnd.failed),
  ]) {
    test('the phone saying ${reason.name} ends as ${end.name}', () async {
      await viewer.start('pixel');

      route.onDeny(pixel, StartDeny(reason: reason));
      await settle();

      expect(viewer.current?.phase, ViewPhase.ended);
      expect(viewer.current?.end, end);
      expect(viewer.lastEndFor('pixel'), end);
      expect(viewer.lastRecord, isNull, reason: 'nothing was shown');
      expect(decodersMade, 0);
    });
  }

  test('a phone that says no right away never waits', () async {
    await viewer.dispose();
    await create(
      answer: (_) => StartDeny(reason: .DENY_REASON_TURNED_OFF),
    );

    await viewer.start('pixel');

    expect(viewer.current?.end, ViewEnd.turnedOff);
  });

  test('a phone that doesn\'t answer, or isn\'t there, says so', () async {
    pixel.answer = null;
    await viewer.start('pixel');
    expect(viewer.current?.end, ViewEnd.noAnswer);

    await viewer.start('gone');
    expect(viewer.current?.end, ViewEnd.notConnected);
    expect(viewer.current?.deviceId, 'gone');
  });

  test('the phone stopping ends the picture with why', () async {
    await stream();
    now = now.add(const Duration(minutes: 12));

    route.onStop(pixel, Stop(reason: .STOP_REASON_STOPPED_ON_SOURCE));
    await settle();

    expect(viewer.current?.end, ViewEnd.stoppedOnPhone);
    expect(viewer.picture.value, isNull);
    expect(decoder.disposed, isTrue);
    expect(pixel.sentOf<Stop>(), isEmpty, reason: 'no echo');
    expect(viewer.lastRecord?.end, MirrorEnd.stoppedOnPhone);
    expect(viewer.lastRecord?.duration, const Duration(minutes: 12));
    expect(viewer.lastRecord?.role, MirrorRole.viewed);
  });

  test('the phone locking is told apart from Stop', () async {
    await stream();

    route.onStop(pixel, Stop(reason: .STOP_REASON_SYSTEM_ENDED));
    await settle();

    expect(viewer.current?.end, ViewEnd.systemEnded);
  });

  test('Stop on the computer tells the phone and records it', () async {
    await stream();

    await viewer.stop();

    expect(viewer.current?.end, ViewEnd.stoppedHere);
    expect(
      pixel.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_VIEWER_DONE,
    );
    expect(decoder.disposed, isTrue);
    final history = MirroringSettings(host.settings).history;
    expect(history.single.end, MirrorEnd.viewerDone);
    expect(history.single.deviceName, 'Pixel');

    route.onFrame(pixel, frame(5, keyframe: true));
    expect(decoder.frames, hasLength(1), reason: 'late frames are ignored');
  });

  test('giving up while the phone asks takes the question back', () async {
    await viewer.start('pixel');

    await viewer.stop();

    expect(
      pixel.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_VIEWER_DONE,
    );
    expect(viewer.lastRecord, isNull);

    route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
    expect(viewer.current?.phase, ViewPhase.ended, reason: 'a late yes');
    expect(decodersMade, 0);
  });

  test('a lost connection ends it', () async {
    await stream();
    host.sessions = [];

    route.onSessionClosed('pixel');
    await settle();

    expect(viewer.current?.end, ViewEnd.lostConnection);
    expect(viewer.lastRecord?.end, MirrorEnd.lostConnection);
    expect(decoder.disposed, isTrue);
  });

  test('nobody answering on the phone, or no picture after the yes, times '
      'out', () {
    fakeAsync((async) {
      create();
      async.flushMicrotasks();
      viewer.start('pixel');
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 66));
      expect(viewer.current?.end, ViewEnd.timedOut);
      expect(pixel.sentOf<Stop>(), hasLength(1));

      viewer.start('pixel');
      async.flushMicrotasks();
      route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
      async.elapse(const Duration(seconds: 11));
      expect(viewer.current?.end, ViewEnd.noAnswer);
      disposeIn(async);
    });
  });

  test('frames wait while the decoder is set up, then play in order', () async {
    final gate = Completer<void>();
    decoder.configureGate = gate;
    await viewer.start('pixel');
    route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
    route.onConfig(pixel, config());

    route
      ..onFrame(pixel, frame(0, keyframe: true))
      ..onFrame(pixel, frame(1));
    expect(decoder.frames, isEmpty);

    gate.complete();
    await settle();
    expect(decoder.frames.map((frame) => frame.ptsUs), [0, 1000]);
  });

  test('frames of another config, and before a keyframe, are '
      'dropped', () async {
    await viewer.start('pixel');
    route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
    route.onConfig(pixel, config());
    await settle();

    route
      ..onFrame(pixel, frame(0))
      ..onFrame(pixel, frame(1, keyframe: true, configId: 9))
      ..onFrame(pixel, frame(2, keyframe: true))
      ..onFrame(pixel, frame(3));

    expect(decoder.frames.map((frame) => frame.ptsUs), [2000, 3000]);
  });

  test('a decoding error asks for a keyframe and skips to it', () async {
    await stream();

    decoder.fail();
    route.onFrame(pixel, frame(1));
    await settle();
    expect(pixel.sentOf<KeyframeRequest>(), hasLength(1));
    expect(decoder.frames, hasLength(1));

    decoder.fail();
    await settle();
    expect(pixel.sentOf<KeyframeRequest>(), hasLength(1), reason: 'not twice');

    route.onFrame(pixel, frame(2, keyframe: true));
    expect(decoder.frames, hasLength(2));
  });

  test('a decoder that falls behind drops to the next keyframe', () async {
    await viewer.dispose();
    await create(withDecoder: FakeDecoder(autoShow: false));
    await viewer.start('pixel');
    route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
    route.onConfig(pixel, config());
    await settle();

    route.onFrame(pixel, frame(0, keyframe: true));
    for (var sequence = 1; sequence <= 20; sequence++) {
      route.onFrame(pixel, frame(sequence));
    }

    await settle();
    expect(decoder.frames, hasLength(12));
    expect(pixel.sentOf<KeyframeRequest>(), hasLength(1));
  });

  test('a rotation reconfigures the decoder', () async {
    await stream();

    route.onConfig(
      pixel,
      StreamConfig(configId: 2, codec: .CODEC_H264, width: 2400, height: 1080),
    );
    await settle();
    route
      ..onFrame(pixel, frame(1))
      ..onFrame(pixel, frame(2, keyframe: true, configId: 2));
    await settle();

    expect(decoder.configs.last.width, 2400);
    expect(decoder.frames.last.ptsUs, 2000);
    expect(viewer.current?.config?.width, 2400);
    expect(viewer.picture.value?.width, 2400);
  });

  test('a stream this computer can\'t decode ends with that, and stops the '
      'phone', () async {
    await viewer.dispose();
    await create(withDecoder: FakeDecoder(failConfigure: true));
    await viewer.start('pixel');
    route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));

    route.onConfig(pixel, config());
    await settle();

    expect(viewer.current?.end, ViewEnd.decoderFailed);
    expect(
      pixel.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_VIEWER_DONE,
    );
  });

  test('the screen going off and on is shown', () async {
    await stream();

    route.onSourceState(pixel, SourceState(screenOff: true));
    expect(viewer.current?.screenOff, isTrue);

    route.onSourceState(pixel, SourceState());
    expect(viewer.current?.screenOff, isFalse);
  });

  test('frames from a phone nobody watches are answered with Stop, once a '
      'second', () async {
    route
      ..onFrame(pixel, frame(0, keyframe: true))
      ..onFrame(pixel, frame(1));
    await settle();

    expect(
      pixel.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_NOT_MIRRORING,
    );
  });

  test('every second: frames shown, drops counted from gaps, stats sent, '
      'latency from the echo', () {
    fakeAsync((async) {
      create();
      async.flushMicrotasks();
      final ticks = <ViewStats?>[];
      viewer.statsChanges.listen((_) => ticks.add(viewer.current?.stats));
      viewer.start('pixel');
      async.flushMicrotasks();
      route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
      route.onConfig(pixel, config());
      async.flushMicrotasks();

      route
        ..onFrame(pixel, frame(0, keyframe: true))
        ..onFrame(pixel, frame(1))
        ..onFrame(pixel, frame(5, keyframe: true));
      async.elapse(const Duration(seconds: 1));

      final sent = pixel.sentOf<Stats>().single;
      expect(sent.fps, 3);
      expect(sent.droppedFrames, 3);
      expect(sent.sentAtMs.toInt(), now.millisecondsSinceEpoch);
      async.flushMicrotasks();
      expect(ticks.last?.fps, 3);

      now = now.add(const Duration(milliseconds: 40));
      route.onStats(
        pixel,
        Stats(echoSentAtMs: sent.sentAtMs, bitrateKbps: 5200),
      );
      expect(viewer.current?.stats.latencyMs, 20);
      expect(viewer.current?.stats.bitrateKbps, 5200);
      async.flushMicrotasks();
      expect(ticks, hasLength(2));
      disposeIn(async);
    });
  });

  test('starting again with the same phone keeps the session; another '
      'phone replaces it', () async {
    final tablet = FakeSession(
      'tablet',
      name: 'Tablet',
      answer: (_) => StartPending(timeoutSeconds: 60),
    );
    host.sessions = [pixel, tablet];
    await stream();

    await viewer.start('pixel');
    expect(pixel.requests, hasLength(1));
    expect(viewer.current?.phase, ViewPhase.streaming);

    await viewer.start('tablet');
    expect(pixel.sentOf<Stop>(), hasLength(1));
    expect(viewer.current?.deviceName, 'Tablet');
    expect(viewer.current?.phase, ViewPhase.waitingForPhone);
  });

  test('an attempt that is over can be dismissed; a live one can\'t', () async {
    await viewer.start('pixel');
    viewer.dismiss();
    expect(viewer.current, isNotNull);

    route.onDeny(pixel, StartDeny(reason: .DENY_REASON_DENIED));
    await settle();
    viewer.dismiss();
    expect(viewer.current, isNull);
    expect(viewer.lastEndFor('pixel'), ViewEnd.denied);
  });
}
