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
  late FakeCamera camera;
  late CameraSource source;
  late DateTime now;
  var screenBusy = false;

  StartRequest request({
    List<AudioCodec> sound = const [.AUDIO_CODEC_OPUS],
    CameraLens? lens,
    int version = 1,
  }) => StartRequest(
    version: version,
    codecs: const [.CODEC_H264],
    maxWidth: 1280,
    maxHeight: 1280,
    maxFps: 30,
    audioCodecs: sound,
    source: .SOURCE_CAMERA,
    camera: switch (lens) {
      final lens? => CameraOptions(lens: lens),
      null => null,
    },
  );

  Future<void> create({FakeCamera? phone}) async {
    host = await FakeHost.create();
    mac = FakeSession('mac', name: 'MacBook', flags: const ['view']);
    host.sessions = [mac];
    camera = phone ?? FakeCamera();
    screenBusy = false;
    now = DateTime(2026, 11, 20, 9, 30);
    source = CameraSource(
      host: host,
      featureId: MirroringFeature.featureId,
      capture: camera,
      settings: MirroringSettings(host.settings),
      texts: cameraTextsFor,
      isBusy: () => screenBusy,
      clock: () => now,
    );
    await source.start();
  }

  Future<void> turnOn({ControlChoice choice = .once}) async {
    await source.onRequest(mac, request());
    await source.answer(choice);
    await settle();
  }

  setUp(create);

  tearDown(() => source.dispose());

  test('a request waits for the owner and starts nothing', () async {
    final reply = await source.onRequest(mac, request());

    expect((reply as StartPending).timeoutSeconds, 60);
    expect(source.pending?.deviceName, 'MacBook');
    expect(source.active, isNull);
    expect(camera.started, isEmpty, reason: 'nothing before the yes');
    expect(mac.sent, isEmpty);
  });

  test('Once turns the camera and the microphone on, says so to the '
      'computer, and asks again next time', () async {
    await turnOn();

    final options = camera.started.single;
    expect(options.lens, MirrorLens.back);
    expect(options.maxLongSide, 1280);
    expect(options.maxShortSide, 720);
    expect(options.fps, 30);
    expect(options.audioCodec, MirrorAudioCodec.opus);
    expect(camera.texts.single.title, 'Camera on for MacBook');
    expect(camera.texts.single.body, 'Sees and hears');
    expect(source.active?.deviceName, 'MacBook');
    expect(source.active?.withSound, isTrue);
    final accept = mac.sentOf<StartAccept>().single;
    expect(accept.codec, Codec.CODEC_H264);
    expect(accept.audio, AudioAnswer.AUDIO_ANSWER_SENDING);
    final state = mac.sentOf<CameraState>().single;
    expect(state.lens, CameraLens.CAMERA_LENS_BACK);
    expect(state.lenses, [
      CameraLens.CAMERA_LENS_BACK,
      CameraLens.CAMERA_LENS_FRONT,
    ]);
    expect(source.alwaysAllowed, isEmpty);

    await source.onStop(mac);
    final again = await source.onRequest(mac, request());

    expect((again as StartPending).timeoutSeconds, 60);
    expect(source.pending, isNotNull);
  });

  test('pictures, their turn and the microphone go to the computer', () async {
    await turnOn();

    camera
      ..play(turn: 90)
      ..emit(
        const CaptureAudioConfigured(
          MirrorAudioConfig(codec: .opus, sampleRate: 48000, channels: 2),
        ),
      )
      ..emit(
        CaptureAudio(
          MirrorAudioPacket(data: Uint8List.fromList([1, 2]), ptsUs: 5),
        ),
      );
    await settle();

    final config = mac.sentOf<StreamConfig>().single;
    expect(config.width, 1280);
    expect(config.height, 720);
    expect(config.turn, 90);
    expect(mac.sentOf<Frame>().single.keyframe, isTrue);
    expect(mac.sentOf<Frame>().single.configId, config.configId);
    expect(mac.sentOf<AudioConfig>().single.channels, 2);
    expect(mac.sentOf<AudioFrame>().single.data, [1, 2]);
  });

  test('what the camera says before the computer heard the yes still '
      'arrives, after it', () async {
    await source.onRequest(mac, request());
    final answered = source.answer(.once);
    await Future<void>.delayed(Duration.zero);
    camera.play();
    await answered;
    await settle();

    final kinds = [for (final message in mac.sent) message.runtimeType];
    expect(kinds.indexOf(StartAccept), lessThan(kinds.indexOf(StreamConfig)));
    expect(mac.sentOf<Frame>(), hasLength(1));
  });

  test('Always is remembered: the next time starts without asking', () async {
    await turnOn(choice: .always);
    expect(source.alwaysAllowed, ['mac']);
    await source.onStop(mac);
    mac.sent.clear();

    final reply = await source.onRequest(mac, request());
    await settle();

    expect((reply as StartPending).timeoutSeconds, 0);
    expect(source.pending, isNull);
    expect(source.active?.deviceId, 'mac');
    expect(camera.started, hasLength(2));
    expect(mac.sentOf<StartAccept>(), hasLength(1));
  });

  test('Ask every time forgets every Always', () async {
    await turnOn(choice: .always);
    await source.onStop(mac);

    await source.forgetAlways();
    await source.onRequest(mac, request());

    expect(source.alwaysAllowed, isEmpty);
    expect(source.pending, isNotNull);
  });

  test('No says so, and the computer can\'t ask again right away', () async {
    await source.onRequest(mac, request());
    await source.answer(.no);

    expect(
      mac.sentOf<StartDeny>().single.reason,
      DenyReason.DENY_REASON_DENIED,
    );
    expect(camera.started, isEmpty);
    final again = await source.onRequest(mac, request());
    expect((again as StartDeny).reason, DenyReason.DENY_REASON_DENIED);

    now = now.add(const Duration(seconds: 31));
    expect(await source.onRequest(mac, request()), isA<StartPending>());
  });

  test('nobody answers: the question goes away after a minute', () {
    fakeAsync((async) {
      source.onRequest(mac, request());
      async.flushMicrotasks();
      expect(source.pending, isNotNull);

      async.elapse(const Duration(seconds: 61));

      expect(source.pending, isNull);
      expect(
        mac.sentOf<StartDeny>().single.reason,
        DenyReason.DENY_REASON_TIMEOUT,
      );
    });
  });

  test('Android\'s camera permission is asked after the yes, with the '
      'microphone', () async {
    await create(
      phone: FakeCamera(cameraGranted: false, microphoneGranted: false),
    );

    await turnOn();

    expect(camera.accessAsks, [true]);
    expect(source.active?.withSound, isTrue);
  });

  test('without Android\'s camera permission nothing starts, and the '
      'computer hears to open Ferret', () async {
    await create(phone: FakeCamera(cameraGranted: false)..grantsCamera = false);

    await turnOn();

    expect(camera.started, isEmpty);
    expect(source.active, isNull);
    expect(source.isBusy, isFalse);
    expect(
      mac.sentOf<StartDeny>().single.reason,
      DenyReason.DENY_REASON_CANNOT_ASK,
    );
  });

  test(
    'a microphone the owner keeps closed only leaves the sound out',
    () async {
      await create(
        phone: FakeCamera(microphoneGranted: false)..grantsMicrophone = false,
      );

      await turnOn();
      camera.emit(
        CaptureAudio(
          MirrorAudioPacket(data: Uint8List.fromList([1]), ptsUs: 5),
        ),
      );
      await settle();

      expect(camera.started.single.audioCodec, isNull);
      expect(camera.texts.single.body, 'Sees');
      expect(source.active?.withSound, isFalse);
      expect(
        mac.sentOf<StartAccept>().single.audio,
        AudioAnswer.AUDIO_ANSWER_OFF,
      );
      expect(mac.sentOf<AudioFrame>(), isEmpty);
    },
  );

  test('a computer that doesn\'t play sound gets pictures only', () async {
    await source.onRequest(mac, request(sound: const []));
    await source.answer(.once);
    await settle();

    expect(camera.accessAsks, isEmpty);
    expect(camera.started.single.audioCodec, isNull);
    expect(
      mac.sentOf<StartAccept>().single.audio,
      AudioAnswer.AUDIO_ANSWER_UNSPECIFIED,
    );
  });

  test('a camera that can\'t start, as from the background, is a no with '
      'a reason', () async {
    camera.starts = false;

    await turnOn();

    expect(source.active, isNull);
    expect(
      mac.sentOf<StartDeny>().single.reason,
      DenyReason.DENY_REASON_CANNOT_ASK,
    );
  });

  test('starts with the camera the computer asks for, and switches', () async {
    await source.onRequest(mac, request(lens: .CAMERA_LENS_FRONT));
    await source.answer(.once);
    await settle();
    expect(camera.started.single.lens, MirrorLens.front);
    expect(mac.sentOf<CameraState>().single.lens, CameraLens.CAMERA_LENS_FRONT);

    await source.onSwitch(mac, CameraSwitch(lens: .CAMERA_LENS_BACK));

    expect(camera.switches, [MirrorLens.back]);
    expect(source.active?.lens, MirrorLens.back);
    expect(mac.sentOf<CameraState>().last.lens, CameraLens.CAMERA_LENS_BACK);
  });

  test('another computer can\'t switch the camera', () async {
    await turnOn();
    final other = FakeSession('other', name: 'iMac', flags: const ['view']);

    await source.onSwitch(other, CameraSwitch(lens: .CAMERA_LENS_FRONT));

    expect(camera.switches, isEmpty);
  });

  test('Stop on the phone closes the camera, tells the computer and '
      'leaves an audit line', () async {
    await turnOn();
    now = now.add(const Duration(minutes: 12));

    await source.stop();

    expect(camera.stops, 1);
    expect(source.active, isNull);
    expect(
      mac.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_STOPPED_ON_SOURCE,
    );
    final record = source.lastRecord;
    expect(record?.camera, isTrue);
    expect(record?.duration, const Duration(minutes: 12));
    expect(MirroringSettings(host.settings).history.single.camera, isTrue);
  });

  test('Stop on Android\'s own notice does the same', () async {
    await turnOn();

    camera.emit(const CaptureEnded(.stoppedByUser));
    await settle();

    expect(source.active, isNull);
    expect(
      mac.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_STOPPED_ON_SOURCE,
    );
  });

  test('another app taking the camera ends it', () async {
    await turnOn();

    camera.emit(const CaptureEnded(.endedBySystem));
    await settle();

    expect(
      mac.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_SYSTEM_ENDED,
    );
    expect(source.lastRecord?.end, MirrorEnd.systemEnded);
  });

  test('the camera never stays on for a computer that dropped off', () async {
    await turnOn();
    host.sessions = [];

    await source.onSessionClosed('mac');

    expect(camera.stops, 1);
    expect(source.active, isNull);
    expect(source.lastRecord?.end, MirrorEnd.lostConnection);
  });

  test('one computer at a time, and not while the screen is shown', () async {
    final other = FakeSession('other', name: 'iMac', flags: const ['view']);
    host.sessions = [mac, other];
    await turnOn();

    final second = await source.onRequest(other, request());
    expect((second as StartDeny).reason, DenyReason.DENY_REASON_BUSY);

    await source.stop();
    screenBusy = true;
    final third = await source.onRequest(other, request());
    expect((third as StartDeny).reason, DenyReason.DENY_REASON_BUSY);
  });

  test('turned off, or turned off for one computer, nobody is asked', () async {
    await source.setEnabled(false);
    final off = await source.onRequest(mac, request());
    expect((off as StartDeny).reason, DenyReason.DENY_REASON_TURNED_OFF);

    await source.setEnabled(true);
    await source.setBlocked('mac', true);
    final blocked = await source.onRequest(mac, request());
    expect((blocked as StartDeny).reason, DenyReason.DENY_REASON_TURNED_OFF);
    expect(source.pending, isNull);
  });

  test('turning it off ends the camera that is on', () async {
    await turnOn();

    await source.setEnabled(false);

    expect(camera.stops, 1);
    expect(mac.sentOf<Stop>().single.reason, StopReason.STOP_REASON_TURNED_OFF);
  });

  test('a phone without a camera, a viewer without H.264 and a newer '
      'viewer are turned away with why', () async {
    final newer = await source.onRequest(mac, request(version: 2));
    expect((newer as StartDeny).reason, DenyReason.DENY_REASON_VERSION);

    final jpegOnly = await source.onRequest(
      mac,
      StartRequest(
        version: 1,
        codecs: const [.CODEC_JPEG],
        source: .SOURCE_CAMERA,
      ),
    );
    expect((jpegOnly as StartDeny).reason, DenyReason.DENY_REASON_NO_CODEC);

    await source.dispose();
    await create(phone: FakeCamera(lenses: const []));
    final none = await source.onRequest(mac, request());
    expect((none as StartDeny).reason, DenyReason.DENY_REASON_UNSUPPORTED);
  });

  test('the computer\'s numbers pick the bitrate, and get an answer', () async {
    await turnOn();
    camera.play();
    await settle();

    await source.onStats(
      mac,
      Stats(sentAtMs: Int64(77), fps: 20, droppedFrames: 4),
    );

    expect(camera.bitrates.single, lessThan(MirrorProtocol.cameraStartBitrate));
    final answer = mac.sentOf<Stats>().single;
    expect(answer.echoSentAtMs, Int64(77));
    expect(answer.fps, 1);
  });

  test('a keyframe is only made for the computer that watches', () async {
    await turnOn();
    final other = FakeSession('other', name: 'iMac', flags: const ['view']);

    await source.onKeyframeRequest(other);
    await source.onKeyframeRequest(mac);

    expect(camera.keyframeRequests, 1);
  });
}
