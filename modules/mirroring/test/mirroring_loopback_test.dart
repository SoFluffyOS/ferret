import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';

import 'helpers/fakes.dart';
import 'helpers/memory_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryDiscoveryBus bus;
  final engines = <FerretEngine>[];

  setUp(() => bus = MemoryDiscoveryBus());

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  Future<FerretEngine> startEngine(
    String name,
    MirroringFeature feature,
  ) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [feature],
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<void> until(bool Function() condition) async {
    for (var attempt = 0; attempt < 300; attempt++) {
      if (condition()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    fail('Timed out waiting');
  }

  Future<String> pair(FerretEngine computer, FerretEngine phone) async {
    final handle = await computer.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The pairing offer should parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await phone.pairWithOffer(offer), isA<Paired>());
    await until(
      () => computer.sessions.isNotEmpty && phone.sessions.isNotEmpty,
    );
    return computer.sessions.single.remoteDeviceId;
  }

  test('a computer asks, the owner says yes, H.264 frames arrive, and Stop '
      'on the phone cuts it', () async {
    final capture = FakeCapture();
    final decoder = FakeDecoder();
    final phoneFeature = MirroringFeature(
      capture: () => capture,
      canShare: true,
      canView: false,
      texts: textsFor,
    );
    final macFeature = MirroringFeature(
      decoder: () => decoder,
      codecs: const [.h264, .jpeg],
      canShare: false,
      canView: true,
    );
    final mac = await startEngine('MacBook', macFeature);
    final phone = await startEngine('Pixel', phoneFeature);
    final phoneId = await pair(mac, phone);
    final viewer = macFeature.viewer;
    final source = phoneFeature.source;
    if (viewer == null || source == null) {
      fail('Both sides should be set up');
    }

    expect(macFeature.canViewDevice(mac.sessions.single), isTrue);
    expect(phoneFeature.canViewDevice(phone.sessions.single), isFalse);

    await viewer.show(phoneId);
    expect(viewer.current?.phase, ViewPhase.waitingForPhone);
    await until(() => capture.asked.isNotEmpty);
    expect(capture.asked.single.askTitle, 'MacBook wants to see this screen');

    capture.answer(.granted);
    await until(() => viewer.current?.phase == .starting);
    await until(() => capture.started.isNotEmpty);
    expect(capture.started.single.codec, MirrorCodec.h264);

    capture
      ..emit(
        CaptureConfigured(
          MirrorStreamConfig(
            codec: .h264,
            width: 1080,
            height: 2400,
            fps: 60,
            sps: Uint8List.fromList([0x67, 0x42]),
            pps: Uint8List.fromList([0x68, 0xce]),
          ),
        ),
      )
      ..emit(
        CaptureFrame(
          MirrorFrame(
            data: Uint8List.fromList([0, 0, 0, 1, 0x65, 9, 9]),
            ptsUs: 1000,
            keyframe: true,
          ),
        ),
      )
      ..emit(
        CaptureFrame(
          MirrorFrame(
            data: Uint8List.fromList([0, 0, 0, 1, 0x41, 7]),
            ptsUs: 17666,
            keyframe: false,
          ),
        ),
      );
    await until(() => decoder.frames.length == 2);

    expect(viewer.current?.phase, ViewPhase.streaming);
    expect(decoder.configs.single.sps, [0x67, 0x42]);
    expect(decoder.frames.first.data, [0, 0, 0, 1, 0x65, 9, 9]);
    expect(decoder.frames.first.keyframe, isTrue);
    expect(decoder.frames.last.ptsUs, 17666);

    decoder.fail();
    await until(() => capture.keyframeRequests == 1);

    await source.stop();
    await until(() => viewer.current?.phase == .ended);
    expect(viewer.current?.end, ViewEnd.stoppedOnPhone);
    expect(capture.stops, 1);
    expect(phoneFeature.settings.history.single.deviceName, 'MacBook');
    expect(phoneFeature.settings.history.single.role, MirrorRole.shared);
    expect(macFeature.settings.history.single.deviceName, 'Pixel');
    expect(macFeature.settings.history.single.role, MirrorRole.viewed);
  });

  test('with Send sound too on, what the phone plays reaches the '
      'computer\'s speaker along with the screen', () async {
    final capture = FakeCapture()..soundNow = .ready;
    final speaker = FakeAudioSink();
    final phoneFeature = MirroringFeature(
      capture: () => capture,
      canShare: true,
      canView: false,
      texts: textsFor,
    );
    final macFeature = MirroringFeature(
      decoder: FakeDecoder.new,
      codecs: const [.h264],
      audioSink: () => speaker,
      audioCodecs: const [.opus],
      canShare: false,
      canView: true,
    );
    final mac = await startEngine('MacBook', macFeature);
    final phone = await startEngine('Pixel', phoneFeature);
    final phoneId = await pair(mac, phone);
    final viewer = macFeature.viewer;
    final source = phoneFeature.source;
    if (viewer == null || source == null) {
      fail('Both sides should be set up');
    }

    expect(await source.setSendSound(true), isTrue);
    await viewer.show(phoneId);
    await until(() => capture.asked.isNotEmpty);
    expect(
      capture.asked.single.sharingTitle,
      'Sharing screen and sound with MacBook',
    );

    capture.answer(.granted);
    await until(() => capture.started.isNotEmpty);
    expect(capture.started.single.audioCodec, MirrorAudioCodec.opus);

    capture.emit(const CaptureAudioConfigured(MirrorAudioConfig(codec: .opus)));
    await until(() => viewer.current?.sound == .playing);
    for (var index = 0; index < 5; index++) {
      capture.emit(
        CaptureAudio(
          MirrorAudioPacket(
            data: Uint8List.fromList([0xFC, index]),
            ptsUs: index * 20000,
          ),
        ),
      );
    }

    await until(() => speaker.played.length == 5);
    expect(speaker.played.last.data, [0xFC, 4]);
    expect(speaker.played.last.ptsUs, 80000);

    await viewer.stop();
    await until(() => capture.stops == 1);
    expect(speaker.disposed, isTrue);
  });

  test('JPEG fallback: a computer without a video decoder gets pictures '
      'through the Dart decoder, and its Stop ends the capture', () async {
    final capture = FakeCapture();
    final decodedBytes = <List<int>>[];
    final image = await createTestImage(width: 4, height: 2);
    final decoder = JpegMirrorDecoder(
      decodeImage: (bytes) async {
        decodedBytes.add(bytes);
        return image.clone();
      },
    );
    final phoneFeature = MirroringFeature(
      capture: () => capture,
      canShare: true,
      canView: false,
      texts: textsFor,
    );
    final pcFeature = MirroringFeature(
      decoder: () => decoder,
      codecs: const [.jpeg],
      canShare: false,
      canView: true,
    );
    final pc = await startEngine('Desktop', pcFeature);
    final phone = await startEngine('Pixel', phoneFeature);
    final phoneId = await pair(pc, phone);
    final viewer = pcFeature.viewer;
    if (viewer == null) {
      fail('The computer should be able to view');
    }

    await viewer.show(phoneId);
    await until(() => capture.asked.isNotEmpty);
    capture.answer(.granted);
    await until(() => capture.started.isNotEmpty);
    expect(capture.started.single.codec, MirrorCodec.jpeg);
    expect(capture.started.single.fps, MirrorProtocol.jpegFps);

    capture
      ..emit(
        const CaptureConfigured(
          MirrorStreamConfig(codec: .jpeg, width: 4, height: 2, fps: 10),
        ),
      )
      ..emit(
        CaptureFrame(
          MirrorFrame(
            data: Uint8List.fromList([0xff, 0xd8, 1, 0xff, 0xd9]),
            ptsUs: 100,
            keyframe: true,
          ),
        ),
      );
    await until(() => viewer.current?.phase == .streaming);

    expect(decodedBytes.single, [0xff, 0xd8, 1, 0xff, 0xd9]);
    expect(viewer.current?.config?.codec, MirrorCodec.jpeg);
    final picture = viewer.picture.value;
    expect(picture, isA<ImagePicture>());
    expect((picture?.width, picture?.height), (4, 2));

    await viewer.stop();
    await until(() => capture.stops == 1);
    expect(phoneFeature.source?.active, isNull);
    expect(phoneFeature.settings.history.single.end, MirrorEnd.viewerDone);
    image.dispose();
  });

  test('a dropped connection: the phone keeps its capture for a moment, and '
      'the computer waits for the phone', () async {
    final capture = FakeCapture();
    final phoneFeature = MirroringFeature(
      capture: () => capture,
      canShare: true,
      canView: false,
      texts: textsFor,
    );
    final macFeature = MirroringFeature(
      decoder: FakeDecoder.new,
      codecs: const [.h264],
      canShare: false,
      canView: true,
    );
    final mac = await startEngine('MacBook', macFeature);
    final phone = await startEngine('Pixel', phoneFeature);
    final phoneId = await pair(mac, phone);
    await macFeature.viewer?.show(phoneId);
    await until(() => capture.asked.isNotEmpty);
    capture.answer(.granted);
    await until(() => macFeature.viewer?.current?.phase == .starting);

    await phone.stop();
    engines.remove(phone);

    await until(() => macFeature.viewer?.current?.phase == .reconnecting);
    expect(macFeature.viewer?.current?.isLive, isTrue);
    await until(() => phoneFeature.source?.active?.reconnecting ?? false);
    expect(capture.stops, 0);
  });

  test('a computer uses the phone\'s camera: Once on the phone, the '
      'picture turned upright with the microphone\'s sound, a lens switch, '
      'and Stop on the phone', () async {
    final camera = FakeCamera();
    final decoder = FakeDecoder();
    final speaker = FakeAudioSink();
    final phoneFeature = MirroringFeature(
      camera: () => camera,
      canShare: false,
      canShareCamera: true,
      canView: false,
      cameraTexts: cameraTextsFor,
    );
    final macFeature = MirroringFeature(
      decoder: () => decoder,
      codecs: const [.h264],
      audioSink: () => speaker,
      audioCodecs: const [.opus],
      canShare: false,
      canShareCamera: false,
      canView: true,
    );
    final mac = await startEngine('MacBook', macFeature);
    final phone = await startEngine('Pixel', phoneFeature);
    final phoneId = await pair(mac, phone);
    final viewer = macFeature.viewer;
    final source = phoneFeature.camera;
    if (viewer == null || source == null) {
      fail('Both sides should be set up');
    }

    expect(macFeature.canUseCameraOf(mac.sessions.single), isTrue);
    expect(macFeature.canViewDevice(mac.sessions.single), isFalse);
    expect(phoneFeature.canUseCameraOf(phone.sessions.single), isFalse);

    await viewer.showCamera(phoneId);
    await until(() => source.pending != null);
    expect(source.pending?.deviceName, 'MacBook');
    expect(viewer.current?.phase, ViewPhase.waitingForPhone);
    expect(viewer.current?.isCamera, isTrue);

    await source.answer(.once);
    await until(() => camera.started.isNotEmpty);
    expect(camera.started.single.maxLongSide, 1280);
    expect(camera.started.single.maxShortSide, 720);
    expect(camera.started.single.audioCodec, MirrorAudioCodec.opus);
    expect(camera.texts.single.title, 'Camera on for MacBook');

    camera.play(turn: 90);
    await until(() => decoder.frames.length == 1);
    await until(() => viewer.current?.lenses.length == 2);
    expect(viewer.current?.lens, MirrorLens.back);
    expect(viewer.current?.nextLens, MirrorLens.front);
    final picture = viewer.picture.value;
    expect(picture, isA<TurnedPicture>());
    expect(picture?.width, 720);
    expect(picture?.height, 1280);

    final image = await createTestImage(width: 4, height: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    decoder.png = png?.buffer.asUint8List();
    final folder = await Directory.systemTemp.createTemp('ferret_camera');
    addTearDown(() => folder.delete(recursive: true));
    final path = '${folder.path}/camera.png';
    expect(await viewer.savePicture(path), isTrue);
    final saved = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
    );
    final turned = (await saved.getNextFrame()).image;
    expect((turned.width, turned.height), (2, 4));

    camera.emit(const CaptureAudioConfigured(MirrorAudioConfig(codec: .opus)));
    await until(() => viewer.current?.sound == .playing);
    for (var index = 0; index < 5; index++) {
      camera.emit(
        CaptureAudio(
          MirrorAudioPacket(
            data: Uint8List.fromList([0xFC, index]),
            ptsUs: index * 20000,
          ),
        ),
      );
    }

    await until(() => speaker.played.length == 5);

    await viewer.setLens(.front);
    await until(() => viewer.current?.lens == MirrorLens.front);
    expect(camera.switches, [MirrorLens.front]);
    expect(macFeature.settings.cameraLens, MirrorLens.front);

    await source.stop();
    await until(() => viewer.current?.phase == .ended);
    expect(viewer.current?.end, ViewEnd.stoppedOnPhone);
    expect(camera.stops, 1);
    expect(phoneFeature.settings.history.single.camera, isTrue);
    expect(macFeature.settings.history.single.camera, isTrue);
  });

  test(
    'a phone without the camera flag is never asked for its camera',
    () async {
      final capture = FakeCapture();
      final phoneFeature = MirroringFeature(
        capture: () => capture,
        canShare: true,
        canShareCamera: false,
        canView: false,
        texts: textsFor,
      );
      final macFeature = MirroringFeature(
        decoder: FakeDecoder.new,
        codecs: const [.h264],
        canShare: false,
        canShareCamera: false,
        canView: true,
      );
      final mac = await startEngine('MacBook', macFeature);
      final phone = await startEngine('Pixel', phoneFeature);
      final phoneId = await pair(mac, phone);
      final viewer = macFeature.viewer;
      if (viewer == null) {
        fail('The computer should be able to view');
      }

      expect(macFeature.canUseCameraOf(mac.sessions.single), isFalse);

      await viewer.showCamera(phoneId);
      await until(() => viewer.current?.phase == .ended);
      expect(viewer.current?.end, ViewEnd.unsupported);
      expect(capture.asked, isEmpty, reason: 'its screen is not asked for');
    },
  );
}
