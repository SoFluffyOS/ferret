import 'dart:typed_data';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCameraApi implements CameraCaptureHostApi {
  NativeCameraSupport supported = NativeCameraSupport(
    h264: true,
    lenses: [.back, .front],
    cameraGranted: false,
    microphoneGranted: false,
  );
  NativeCameraOptions? options;
  NativeCameraTexts? texts;
  NativeCameraLens? startsWith = .back;
  final List<String> calls = [];

  @override
  Future<NativeCameraSupport> support() async => supported;

  @override
  Future<NativeCameraSupport> requestAccess(bool withMicrophone) async {
    calls.add('ask $withMicrophone');
    supported = NativeCameraSupport(
      h264: true,
      lenses: [.back, .front],
      cameraGranted: true,
      microphoneGranted: withMicrophone,
    );
    return supported;
  }

  @override
  Future<NativeCameraLens?> start(
    NativeCameraOptions options,
    NativeCameraTexts texts,
  ) async {
    this.options = options;
    this.texts = texts;
    return startsWith;
  }

  @override
  Future<NativeCameraLens?> setLens(NativeCameraLens lens) async {
    calls.add('lens ${lens.name}');
    return lens;
  }

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> requestKeyframe() async => calls.add('keyframe');

  @override
  Future<void> setBitrate(int bitrate) async => calls.add('bitrate $bitrate');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const texts = CameraTexts(
  title: 'Camera on for MacBook',
  body: 'It sees and hears through this phone',
  stopLabel: 'Stop',
  channelName: 'Camera for a computer',
);

const options = CameraCaptureOptions(
  lens: .front,
  maxLongSide: 1280,
  maxShortSide: 720,
  fps: 30,
  bitrate: 2500000,
  audioCodec: .opus,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCameraApi api;
  late AndroidCameraCapture capture;

  setUp(() {
    api = FakeCameraApi();
    capture = AndroidCameraCapture(api: api);
  });

  tearDown(() => capture.dispose());

  test('says which cameras there are and what Android allows', () async {
    final support = await capture.support();

    expect(support.canCapture, isTrue);
    expect(support.lenses, [MirrorLens.back, MirrorLens.front]);
    expect(support.cameraGranted, isFalse);
  });

  test('a phone without a camera cannot send one', () async {
    api.supported = NativeCameraSupport(
      h264: true,
      lenses: [],
      cameraGranted: true,
      microphoneGranted: true,
    );

    expect((await capture.support()).canCapture, isFalse);
  });

  test('asks for the camera and the microphone together', () async {
    final support = await capture.requestAccess(withMicrophone: true);

    expect(api.calls, ['ask true']);
    expect(support.cameraGranted, isTrue);
    expect(support.microphoneGranted, isTrue);
  });

  test('starts with the options and the notice words', () async {
    final lens = await capture.start(options, texts);

    expect(lens, MirrorLens.back);
    expect(api.options?.lens, NativeCameraLens.front);
    expect(api.options?.maxLongSide, 1280);
    expect(api.options?.fps, 30);
    expect(api.options?.audioCodec, NativeAudioCodec.opus);
    expect(api.texts?.title, 'Camera on for MacBook');
    expect(api.texts?.stopLabel, 'Stop');
  });

  test('a camera that did not start answers with none', () async {
    api.startsWith = null;

    expect(await capture.start(options, texts), isNull);
  });

  test('switches, stops and steers the encoder', () async {
    expect(await capture.setLens(.front), MirrorLens.front);
    await capture.requestKeyframe();
    await capture.setBitrate(1500000);
    await capture.stop();

    expect(api.calls, ['lens front', 'keyframe', 'bitrate 1500000', 'stop']);
  });

  test('hands on configs with their turn, frames, sound and the end', () async {
    final events = <CaptureEvent>[];
    final subscription = capture.events.listen(events.add);

    capture
      ..onConfig(
        NativeStreamConfig(
          codec: .h264,
          width: 1280,
          height: 720,
          rotation: 0,
          fps: 30,
          sps: Uint8List.fromList([1]),
          pps: Uint8List.fromList([2]),
          turn: 90,
        ),
      )
      ..onFrame(
        NativeFrame(data: Uint8List.fromList([3]), ptsUs: 10, keyframe: true),
      )
      ..onAudioConfig(.opus, 48000, 2)
      ..onAudioFrame(Uint8List.fromList([4]), 20)
      ..onAudioEnded()
      ..onEnded(.stoppedByUser);
    await subscription.cancel();

    final config = (events[0] as CaptureConfigured).config;
    expect(config.width, 1280);
    expect(config.turn, 90);
    expect((events[1] as CaptureFrame).frame.keyframe, isTrue);
    expect((events[2] as CaptureAudioConfigured).config.channels, 2);
    expect((events[3] as CaptureAudio).packet.ptsUs, 20);
    expect(events[4], isA<CaptureAudioEnded>());
    expect((events[5] as CaptureEnded).end, CaptureEnd.stoppedByUser);
  });

  test('a turned picture swaps its sides', () {
    const picture = TexturePicture(textureId: 1, width: 1280, height: 720);

    expect(TurnedPicture.of(picture, 0), same(picture));
    expect(TurnedPicture.of(picture, 90).width, 720);
    expect(TurnedPicture.of(picture, 90).height, 1280);
    expect(TurnedPicture.of(picture, 180).width, 1280);
    expect(TurnedPicture.of(picture, 270).height, 1280);
  });

  test('a phone\'s camera and its screen are different targets', () {
    const screen = MirrorTarget(routeId: 'ferret', id: 'pixel', name: 'Pixel');
    const camera = MirrorTarget(
      routeId: 'ferret',
      id: 'pixel',
      name: 'Pixel',
      camera: true,
    );

    expect(screen == camera, isFalse);
  });
}
