import 'dart:typed_data';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protocol/mirroring.dart';

import 'helpers/fakes.dart';

/// Sound over Ferret's own route, one side at a time: what the phone
/// answers and sends, and what the computer makes of it.
void main() {
  group('the phone', () {
    late FakeHost host;
    late FakeSession mac;
    late FakeCapture capture;
    late MirrorSource source;
    late MirroringSettings settings;

    StartRequest request({
      List<AudioCodec> audio = const [.AUDIO_CODEC_OPUS],
    }) => StartRequest(
      version: 1,
      codecs: const [.CODEC_H264],
      audioCodecs: audio,
    );

    MirrorAudioPacket packet(int index) => MirrorAudioPacket(
      data: Uint8List.fromList([0xFC, index]),
      ptsUs: index * 20000,
    );

    Future<void> create({
      AudioCaptureSupport sound = .ready,
      bool sendSound = true,
    }) async {
      host = await FakeHost.create(
        settings: {MirroringSettings.sendSoundKey: sendSound},
      );
      mac = FakeSession('mac', name: 'MacBook', flags: const ['view']);
      host.sessions = [mac];
      capture = FakeCapture()..soundNow = sound;
      settings = MirroringSettings(host.settings);
      source = MirrorSource(
        host: host,
        featureId: MirroringFeature.featureId,
        capture: capture,
        settings: settings,
        texts: textsFor,
      );
      await source.start();
    }

    Future<void> share(StartRequest asked) async {
      await source.onRequest(mac, asked);
      await settle();
      capture.answer(.granted);
      await settle();
    }

    tearDown(() => source.dispose());

    test('sends its sound when its owner turned that on, and says so on '
        'the notice', () async {
      await create();

      await share(request());

      final accept = mac.sentOf<StartAccept>().single;
      expect(accept.audio, AudioAnswer.AUDIO_ANSWER_SENDING);
      expect(accept.audioCodec, AudioCodec.AUDIO_CODEC_OPUS);
      expect(capture.started.single.audioCodec, MirrorAudioCodec.opus);
      expect(
        capture.asked.single.sharingTitle,
        'Sharing screen and sound with MacBook',
      );
      expect(source.active?.withSound, isTrue);
    });

    test('the config goes out before the sound, which is numbered', () async {
      await create();
      await share(request());

      capture
        ..emit(const CaptureAudioConfigured(MirrorAudioConfig(codec: .opus)))
        ..emit(CaptureAudio(packet(0)))
        ..emit(CaptureAudio(packet(1)));
      await settle();

      final config = mac.sentOf<AudioConfig>().single;
      expect(config.codec, AudioCodec.AUDIO_CODEC_OPUS);
      expect((config.sampleRate, config.channels), (48000, 2));
      final frames = mac.sentOf<AudioFrame>();
      expect(frames.map((frame) => frame.sequence), [Int64(0), Int64(1)]);
      expect(frames.last.ptsUs, Int64(20000));
      expect(frames.last.data, [0xFC, 1]);
    });

    test(
      'keeps its sound to itself until its owner turns sending on',
      () async {
        await create(sendSound: false);

        await share(request());
        capture
          ..emit(const CaptureAudioConfigured(MirrorAudioConfig(codec: .opus)))
          ..emit(CaptureAudio(packet(0)));
        await settle();

        expect(
          mac.sentOf<StartAccept>().single.audio,
          AudioAnswer.AUDIO_ANSWER_OFF,
        );
        expect(capture.started.single.audioCodec, isNull);
        expect(
          capture.asked.single.sharingTitle,
          'Sharing screen with MacBook',
        );
        expect(mac.sentOf<AudioConfig>(), isEmpty);
        expect(mac.sentOf<AudioFrame>(), isEmpty);
      },
    );

    test('a permission Android took back means no sound', () async {
      await create(sound: .needsPermission);

      await share(request());

      expect(
        mac.sentOf<StartAccept>().single.audio,
        AudioAnswer.AUDIO_ANSWER_OFF,
      );
      expect(capture.started.single.audioCodec, isNull);
    });

    test('says so when this phone cannot capture what it plays', () async {
      await create(sound: .unsupported);

      await share(request());

      expect(
        mac.sentOf<StartAccept>().single.audio,
        AudioAnswer.AUDIO_ANSWER_UNSUPPORTED,
      );
    });

    test('never sends sound to a computer that did not ask', () async {
      await create();

      await share(request(audio: const []));
      capture
        ..emit(const CaptureAudioConfigured(MirrorAudioConfig(codec: .opus)))
        ..emit(CaptureAudio(packet(0)));
      await settle();

      final accept = mac.sentOf<StartAccept>().single;
      expect(accept.audio, AudioAnswer.AUDIO_ANSWER_UNSPECIFIED);
      expect(capture.started.single.audioCodec, isNull);
      expect(mac.sentOf<AudioFrame>(), isEmpty);
    });

    test('sends plain samples to a computer without an Opus decoder', () async {
      await create();

      await share(request(audio: const [.AUDIO_CODEC_PCM_S16LE]));

      expect(
        mac.sentOf<StartAccept>().single.audioCodec,
        AudioCodec.AUDIO_CODEC_PCM_S16LE,
      );
      expect(capture.started.single.audioCodec, MirrorAudioCodec.pcm);
    });

    test('tells the computer when capturing the sound stopped', () async {
      await create();
      await share(request());
      capture.emit(
        const CaptureAudioConfigured(MirrorAudioConfig(codec: .opus)),
      );

      capture
        ..emit(const CaptureAudioEnded())
        ..emit(CaptureAudio(packet(0)));
      await settle();

      expect(mac.sentOf<AudioEnded>(), hasLength(1));
      expect(mac.sentOf<AudioFrame>(), isEmpty);
      expect(source.active, isNotNull, reason: 'the pictures go on');
    });

    test('no sound after Stop', () async {
      await create();
      await share(request());
      capture.emit(
        const CaptureAudioConfigured(MirrorAudioConfig(codec: .opus)),
      );

      await source.stop();
      capture.emit(CaptureAudio(packet(0)));
      await settle();

      expect(mac.sentOf<AudioFrame>(), isEmpty);
    });

    test('turning sending on asks Android once, and stays off after a '
        'no', () async {
      await create(sound: .needsPermission, sendSound: false);
      capture.grantsSound = false;

      expect(await source.setSendSound(true), isFalse);
      expect(capture.soundAsks, 1);
      expect(settings.sendSound, isFalse);
      expect(source.sendsSound, isFalse);

      capture.grantsSound = true;
      expect(await source.setSendSound(true), isTrue);
      expect(settings.sendSound, isTrue);
      expect(source.sendsSound, isTrue);

      expect(await source.setSendSound(false), isTrue);
      expect(source.sendsSound, isFalse);
    });
  });

  group('the computer', () {
    late FakeHost host;
    late FakeSession pixel;
    late FerretRoute route;
    late MirrorRoutes routes;
    late MirrorViewer viewer;
    late MirroringSettings settings;
    late List<FakeAudioSink> sinks;

    StreamConfig config() => StreamConfig(
      configId: 1,
      codec: .CODEC_H264,
      width: 1080,
      height: 2400,
      sps: [0x67],
      pps: [0x68],
    );

    AudioFrame sound(int index) => AudioFrame(
      sequence: Int64(index),
      ptsUs: Int64(index * 20000),
      data: [0xFC, index],
    );

    Future<void> create({
      List<MirrorAudioCodec> audioCodecs = const [.opus, .pcm],
    }) async {
      host = await FakeHost.create();
      pixel = FakeSession(
        'pixel',
        answer: (_) => StartPending(timeoutSeconds: 60),
      );
      host.sessions = [pixel];
      sinks = [];
      settings = MirroringSettings(host.settings);
      route = FerretRoute(host: host, featureId: MirroringFeature.featureId);
      routes = MirrorRoutes(
        ferret: route,
        settings: settings,
        receiverName: () => 'MacBook',
      );
      viewer = MirrorViewer(
        routes: routes,
        createDecoder: FakeDecoder.new,
        codecs: const [.h264],
        settings: settings,
        createAudioSink: () {
          final sink = FakeAudioSink();
          sinks.add(sink);
          return sink;
        },
        audioCodecs: audioCodecs,
      );
    }

    Future<void> stream(AudioAnswer answer) async {
      await viewer.show('pixel');
      route.onAccept(
        pixel,
        StartAccept(version: 1, codec: .CODEC_H264, audio: answer),
      );
      route.onConfig(pixel, config());
      await settle();
    }

    setUp(create);

    tearDown(() async {
      await viewer.dispose();
      await routes.dispose();
    });

    test('asks for the sound it can play, and plays what arrives', () async {
      await stream(.AUDIO_ANSWER_SENDING);
      final request = pixel.requests.single as StartRequest;
      expect(request.audioCodecs, [
        AudioCodec.AUDIO_CODEC_OPUS,
        AudioCodec.AUDIO_CODEC_PCM_S16LE,
      ]);
      expect(viewer.current?.sound, ViewSound.starting);

      route.onAudioConfig(
        pixel,
        AudioConfig(
          codec: .AUDIO_CODEC_OPUS,
          sampleRate: 48000,
          channels: 2,
        ),
      );
      await settle();
      for (var index = 0; index < 4; index++) {
        route.onAudioFrame(pixel, sound(index));
      }

      expect(viewer.current?.sound, ViewSound.playing);
      expect(sinks.single.played, hasLength(4));
    });

    test('a phone that keeps its sound, and one that never heard of '
        'it', () async {
      await stream(.AUDIO_ANSWER_OFF);
      expect(viewer.current?.sound, ViewSound.notAllowed);

      await viewer.stop();
      await stream(.AUDIO_ANSWER_UNSPECIFIED);
      expect(viewer.current?.sound, ViewSound.unsupported);
    });

    test('turning sound off here leaves the phone alone: it would have to '
        'ask its owner again', () async {
      await stream(.AUDIO_ANSWER_SENDING);
      route.onAudioConfig(
        pixel,
        AudioConfig(
          codec: .AUDIO_CODEC_OPUS,
          sampleRate: 48000,
          channels: 2,
        ),
      );
      await settle();

      await viewer.setSound(false);
      route.onAudioFrame(pixel, sound(0));

      expect(pixel.requests, hasLength(1));
      expect(pixel.sentOf<Stop>(), isEmpty);
      expect(viewer.current?.sound, ViewSound.off);
      expect(sinks.single.disposed, isTrue);

      await viewer.setSound(true);
      await settle();

      expect(viewer.current?.sound, ViewSound.playing);
      expect(sinks, hasLength(2));
    });

    test('sound that stops on the phone keeps the picture', () async {
      await stream(.AUDIO_ANSWER_SENDING);

      route.onAudioEnded(pixel);
      await settle();

      expect(viewer.current?.sound, ViewSound.failed);
      expect(viewer.current?.isLive, isTrue);
    });

    test(
      'with sound off, nothing is asked for and nothing is played',
      () async {
        await settings.setSound(false);
        await stream(.AUDIO_ANSWER_SENDING);
        route.onAudioFrame(pixel, sound(0));

        expect((pixel.requests.single as StartRequest).audioCodecs, isEmpty);
        expect(viewer.current?.sound, ViewSound.off);
        expect(sinks, isEmpty);
      },
    );

    test('sound from a phone nobody watches is told to stop', () async {
      route.onAudioFrame(pixel, sound(0));
      await settle();

      expect(
        pixel.sentOf<Stop>().single.reason,
        StopReason.STOP_REASON_NOT_MIRRORING,
      );
    });
  });
}
