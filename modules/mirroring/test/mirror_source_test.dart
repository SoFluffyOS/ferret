import 'dart:async';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protocol/mirroring.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeHost host;
  late FakeSession mac;
  late FakeCapture capture;
  late MirrorSource source;
  late DateTime now;

  StartRequest request({List<Codec>? codecs, int version = 1}) => StartRequest(
    version: version,
    codecs: codecs ?? const [.CODEC_H264, .CODEC_JPEG],
    maxWidth: 1920,
    maxHeight: 1920,
    maxFps: 60,
  );

  Future<void> create({CaptureSupport? support}) async {
    host = await FakeHost.create();
    mac = FakeSession('mac', name: 'MacBook', flags: const ['view']);
    host.sessions = [mac];
    capture = FakeCapture();
    if (support != null) {
      capture.supportNow = support;
    }

    now = DateTime(2026, 11, 18, 21, 10);
    source = MirrorSource(
      host: host,
      featureId: MirroringFeature.featureId,
      capture: capture,
      settings: MirroringSettings(host.settings),
      texts: textsFor,
      clock: () => now,
    );
    await source.start();
  }

  Future<void> share() async {
    await source.onRequest(mac, request());
    capture.answer(.granted);
    await settle();
  }

  setUp(create);

  tearDown(() => source.dispose());

  test('a request shows the system prompt with the computer\'s name and '
      'answers "asking"', () async {
    final reply = await source.onRequest(mac, request());

    expect((reply as StartPending).timeoutSeconds, 60);
    expect(source.pending?.deviceName, 'MacBook');
    expect(capture.asked.single.askTitle, 'MacBook wants to see this screen');
    expect(capture.asked.single.sharingTitle, 'Sharing screen with MacBook');
    expect(capture.started, isEmpty, reason: 'nothing before the yes');
  });

  test('the prompt names the computer as this device calls it', () async {
    await nameHere(host.trustStore, 'mac', 'Studio Mac');

    await source.onRequest(mac, request());

    expect(source.pending?.deviceName, 'Studio Mac');
    expect(
      capture.asked.single.askTitle,
      'Studio Mac wants to see this screen',
    );
  });

  test('a yes accepts, then starts the capture with H.264 inside the '
      'limits', () async {
    await share();

    expect(source.pending, isNull);
    expect(source.active?.deviceName, 'MacBook');
    final accept = mac.sentOf<StartAccept>().single;
    expect(accept.codec, Codec.CODEC_H264);
    expect(accept.version, 1);
    final options = capture.started.single;
    expect(options.codec, MirrorCodec.h264);
    expect((options.maxLongSide, options.maxShortSide), (1920, 1080));
    expect(options.fps, 60);
    expect(options.bitrate, MirrorProtocol.startBitrate);
  });

  test('the config goes out before the frames, with a new id on '
      'rotation', () async {
    await share();

    capture
      ..emit(
        CaptureConfigured(
          MirrorStreamConfig(
            codec: .h264,
            width: 1080,
            height: 2400,
            fps: 60,
            sps: Uint8List.fromList([0x67, 1]),
            pps: Uint8List.fromList([0x68, 2]),
          ),
        ),
      )
      ..emitFrame(keyframe: true, ptsUs: 5)
      ..emitFrame(ptsUs: 6)
      ..emit(
        const CaptureConfigured(
          MirrorStreamConfig(
            codec: .h264,
            width: 2400,
            height: 1080,
            rotation: 90,
          ),
        ),
      )
      ..emitFrame(ptsUs: 7)
      ..emitFrame(keyframe: true, ptsUs: 8);
    await settle();

    final configs = mac.sentOf<StreamConfig>();
    expect(configs.map((config) => config.configId), [1, 2]);
    expect(configs.first.sps, [0x67, 1]);
    expect((configs.last.width, configs.last.rotation), (2400, 90));
    final frames = mac.sentOf<Frame>();
    expect(frames.map((frame) => frame.ptsUs.toInt()), [5, 6, 8]);
    expect(frames.map((frame) => frame.configId), [1, 1, 2]);
    expect(
      mac.sent.indexOf(configs.first),
      lessThan(mac.sent.indexOf(frames.first)),
    );
  });

  test('a backed-up connection drops frames and asks the encoder for a '
      'keyframe once it clears', () async {
    await share();
    capture
      ..emit(
        const CaptureConfigured(
          MirrorStreamConfig(codec: .h264, width: 8, height: 8),
        ),
      )
      ..emitFrame(keyframe: true);
    await settle();
    final gate = Completer<void>();
    mac.sendGate = gate;

    for (var index = 0; index < 10; index++) {
      capture.emitFrame(ptsUs: index);
    }

    expect(mac.sentOf<Frame>(), hasLength(7));
    expect(capture.keyframeRequests, 0);

    mac.sendGate = null;
    gate.complete();
    await settle();
    expect(capture.keyframeRequests, 1);
  });

  test('a no denies, and the same computer is turned away for a '
      'while', () async {
    await source.onRequest(mac, request());
    capture.answer(.denied);
    await settle();

    expect(
      mac.sentOf<StartDeny>().single.reason,
      DenyReason.DENY_REASON_DENIED,
    );
    expect(source.pending, isNull);
    expect(source.active, isNull);
    expect(capture.started, isEmpty);

    final again = await source.onRequest(mac, request());
    expect((again as StartDeny).reason, DenyReason.DENY_REASON_DENIED);
    expect(capture.asked, hasLength(1), reason: 'no second prompt');

    now = now.add(const Duration(seconds: 31));
    expect(await source.onRequest(mac, request()), isA<StartPending>());
  });

  for (final (result, reason) in [
    (ConsentResult.timedOut, DenyReason.DENY_REASON_TIMEOUT),
    (ConsentResult.cannotAsk, DenyReason.DENY_REASON_CANNOT_ASK),
    (ConsentResult.failed, DenyReason.DENY_REASON_FAILED),
  ]) {
    test('${result.name} on the prompt denies with ${reason.name}', () async {
      await source.onRequest(mac, request());
      capture.answer(result);
      await settle();

      expect(mac.sentOf<StartDeny>().single.reason, reason);
      expect(await source.onRequest(mac, request()), isA<StartPending>());
    });
  }

  test('every request asks again: a yes is never remembered', () async {
    await share();
    await source.stop();

    final again = await source.onRequest(mac, request());

    expect(again, isA<StartPending>());
    expect(capture.asked, hasLength(2));
    expect(source.active, isNull);
  });

  test('requests are turned down with the reason', () async {
    expect(
      ((await source.onRequest(mac, request(version: 2))) as StartDeny).reason,
      DenyReason.DENY_REASON_VERSION,
    );
    expect(
      ((await source.onRequest(
        mac,
        request(codecs: const []),
      )) as StartDeny).reason,
      DenyReason.DENY_REASON_NO_CODEC,
    );

    await source.setEnabled(false);
    expect(
      ((await source.onRequest(mac, request())) as StartDeny).reason,
      DenyReason.DENY_REASON_TURNED_OFF,
    );
    expect(capture.asked, isEmpty);
  });

  test('a phone that can\'t capture says so', () async {
    await source.dispose();
    await create(support: const .none());

    final reply = await source.onRequest(mac, request());

    expect((reply as StartDeny).reason, DenyReason.DENY_REASON_UNSUPPORTED);
  });

  test('a viewer without a video decoder gets JPEG, smaller and '
      'slower', () async {
    await source.onRequest(mac, request(codecs: const [.CODEC_JPEG]));
    capture.answer(.granted);
    await settle();

    expect(mac.sentOf<StartAccept>().single.codec, Codec.CODEC_JPEG);
    final options = capture.started.single;
    expect(options.codec, MirrorCodec.jpeg);
    expect(
      (options.maxLongSide, options.maxShortSide, options.fps),
      (
        1280,
        720,
        10,
      ),
    );
  });

  test('one computer at a time', () async {
    final other = FakeSession('other', name: 'Desktop');
    host.sessions = [mac, other];
    await source.onRequest(mac, request());

    expect(
      ((await source.onRequest(other, request())) as StartDeny).reason,
      DenyReason.DENY_REASON_BUSY,
    );
    expect(await source.onRequest(mac, request()), isA<StartPending>());

    capture.answer(.granted);
    await settle();
    expect(
      ((await source.onRequest(other, request())) as StartDeny).reason,
      DenyReason.DENY_REASON_BUSY,
    );
  });

  test('Stop on the phone ends it at once and tells the computer', () async {
    await share();
    now = now.add(const Duration(minutes: 12));

    await source.stop();

    expect(source.active, isNull);
    expect(capture.stops, 1);
    expect(
      mac.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_STOPPED_ON_SOURCE,
    );
    capture.emitFrame(keyframe: true);
    expect(mac.sentOf<Frame>(), isEmpty, reason: 'nothing after Stop');
  });

  for (final (end, reason, recorded) in [
    (
      CaptureEnd.stoppedByUser,
      StopReason.STOP_REASON_STOPPED_ON_SOURCE,
      MirrorEnd.stoppedOnPhone,
    ),
    (
      CaptureEnd.endedBySystem,
      StopReason.STOP_REASON_SYSTEM_ENDED,
      MirrorEnd.systemEnded,
    ),
    (CaptureEnd.failed, StopReason.STOP_REASON_FAILED, MirrorEnd.failed),
  ]) {
    test('the capture ending with ${end.name} tells the computer '
        '${reason.name}', () async {
      await share();

      capture.emit(CaptureEnded(end));
      await settle();

      expect(source.active, isNull);
      expect(mac.sentOf<Stop>().single.reason, reason);
      expect(source.lastRecord?.end, recorded);
    });
  }

  test('the computer stopping ends it without an echo', () async {
    await share();

    await source.onStop(mac);

    expect(source.active, isNull);
    expect(capture.stops, 1);
    expect(mac.sentOf<Stop>(), isEmpty);
    expect(source.lastRecord?.end, MirrorEnd.viewerDone);
  });

  test('the computer giving up takes the prompt back', () async {
    await source.onRequest(mac, request());

    await source.onStop(mac);
    await settle();

    expect(source.pending, isNull);
    expect(capture.cancels, 1);
    expect(mac.sentOf<StartDeny>(), isEmpty);
    expect(mac.sentOf<StartAccept>(), isEmpty);
  });

  test('a yes that comes after the computer left shares nothing', () async {
    capture.cancelClosesPrompt = false;
    await source.onRequest(mac, request());
    host.sessions = [];
    await source.onSessionClosed('mac');
    capture.answer(.granted);
    await settle();

    expect(source.active, isNull);
    expect(capture.started, isEmpty);
    expect(capture.stops, 1, reason: 'the armed service is let go');
  });

  group('a dropped connection', () {
    test('keeps the capture for 20 seconds, then ends sharing and records '
        'it', () {
      fakeAsync((async) {
        create();
        async.flushMicrotasks();
        share();
        async.flushMicrotasks();
        host.sessions = [];

        source.onSessionClosed('mac');
        async.flushMicrotasks();
        expect(source.active?.reconnecting, isTrue);
        expect(capture.stops, 0, reason: 'the owner already said yes to it');

        async.elapse(const Duration(seconds: 19));
        expect(source.active, isNotNull);

        async.elapse(const Duration(seconds: 2));
        expect(source.active, isNull);
        expect(capture.stops, 1);
        expect(source.lastRecord?.end, MirrorEnd.lostConnection);
      });
    });

    test('the same computer coming back in time goes on without a new '
        'prompt, from a fresh config and keyframe', () async {
      await share();
      capture.emit(
        const CaptureConfigured(
          MirrorStreamConfig(codec: .h264, width: 1080, height: 2400),
        ),
      );
      await settle();
      host.sessions = [];
      await source.onSessionClosed('mac');
      final keyframesBefore = capture.keyframeRequests;

      host.sessions = [mac];
      final reply = await source.onRequest(mac, request());
      await settle();

      expect((reply as StartPending).timeoutSeconds, 0);
      expect(capture.asked, hasLength(1), reason: 'no second prompt');
      expect(source.active?.reconnecting, isFalse);
      expect(mac.sentOf<StartAccept>(), hasLength(2));
      expect(mac.sentOf<StreamConfig>().last.configId, 2);
      expect(capture.keyframeRequests, greaterThan(keyframesBefore));
      expect(capture.stops, 0);
    });

    test(
      'another computer is still told the phone is busy meanwhile',
      () async {
        await share();
        host.sessions = [];
        await source.onSessionClosed('mac');
        final other = FakeSession('imac', name: 'iMac', flags: const ['view']);

        final reply = await source.onRequest(other, request());

        expect((reply as StartDeny).reason, DenyReason.DENY_REASON_BUSY);
      },
    );

    test('Stop on the phone ends it at once, also while it waits', () async {
      await share();
      host.sessions = [];
      await source.onSessionClosed('mac');

      await source.stop();

      expect(source.active, isNull);
      expect(source.lastRecord?.end, MirrorEnd.stoppedOnPhone);
    });
  });

  test('a capture that fails to start tells the computer', () async {
    capture.startResult = false;
    await share();

    expect(source.active, isNull);
    expect(mac.sentOf<StartAccept>(), hasLength(1));
    expect(mac.sentOf<Stop>().single.reason, StopReason.STOP_REASON_FAILED);
  });

  test('turning mirroring off ends sharing', () async {
    await share();

    await source.setEnabled(false);

    expect(source.active, isNull);
    expect(mac.sentOf<Stop>().single.reason, StopReason.STOP_REASON_TURNED_OFF);
    expect(source.lastRecord?.end, MirrorEnd.turnedOff);
  });

  test('a keyframe request reaches the encoder, only from the '
      'viewer', () async {
    final other = FakeSession('other');
    await share();

    await source.onKeyframeRequest(other);
    expect(capture.keyframeRequests, 0);

    await source.onKeyframeRequest(mac);
    expect(capture.keyframeRequests, 1);
  });

  test('stats are echoed, and drops lower the bitrate', () async {
    await share();
    capture
      ..emit(
        const CaptureConfigured(
          MirrorStreamConfig(codec: .h264, width: 8, height: 8),
        ),
      )
      ..emitFrame(keyframe: true)
      ..emitFrame();
    await settle();

    await source.onStats(mac, Stats(sentAtMs: Int64(42), droppedFrames: 3));

    final stats = mac.sentOf<Stats>().single;
    expect(stats.echoSentAtMs.toInt(), 42);
    expect(stats.fps, 2);
    expect(stats.bitrateKbps, 2800);
    expect(capture.bitrates, [2800000]);
  });

  test('the audit line: who, how long, when, saved newest first', () async {
    await share();
    now = now.add(const Duration(minutes: 12));
    await source.stop();

    final record = source.lastRecord;
    expect(record?.deviceName, 'MacBook');
    expect(record?.role, MirrorRole.shared);
    expect(record?.duration, const Duration(minutes: 12));
    expect(record?.startedAt, DateTime(2026, 11, 18, 21, 10));

    await share();
    await source.onStop(mac);
    final history = MirroringSettings(host.settings).history;
    expect(history.map((record) => record.end), [
      MirrorEnd.viewerDone,
      MirrorEnd.stoppedOnPhone,
    ]);

    source.dismissRecord();
    expect(source.lastRecord, isNull);
    await source.clearHistory();
    expect(MirroringSettings(host.settings).history, isEmpty);
  });

  test('a request nobody was ever asked about is never recorded', () async {
    await source.onRequest(mac, request());
    capture.answer(.denied);
    await settle();

    expect(source.lastRecord, isNull);
    expect(MirroringSettings(host.settings).history, isEmpty);
  });

  test('asking again while the prompt is up reports the time left', () async {
    await source.onRequest(mac, request());
    now = now.add(const Duration(seconds: 20));

    final again = await source.onRequest(mac, request());

    expect((again as StartPending).timeoutSeconds, 40);
    expect(capture.asked, hasLength(1));
  });
}
