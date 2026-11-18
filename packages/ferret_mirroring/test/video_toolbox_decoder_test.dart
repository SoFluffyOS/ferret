import 'dart:typed_data';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDecoderApi implements MirrorDecoderHostApi {
  final List<String> calls = [];
  bool refuseConfig = false;
  bool fullScreen = false;

  @override
  Future<int> create() async {
    calls.add('create');
    return 11;
  }

  @override
  Future<void> configure(Uint8List sps, Uint8List pps) async {
    if (refuseConfig) {
      throw StateError('bad_config');
    }

    calls.add('configure ${sps.length} ${pps.length}');
  }

  @override
  Future<void> decode(Uint8List data, int ptsUs, bool keyframe) async {
    calls.add('decode $ptsUs $keyframe');
  }

  @override
  Future<void> dispose() async => calls.add('dispose');

  @override
  Future<bool> canFullScreen() async => true;

  @override
  Future<bool> isFullScreen() async => fullScreen;

  @override
  Future<void> setFullScreen(bool fullScreen) async =>
      this.fullScreen = fullScreen;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MirrorStreamConfig h264({int width = 1080, int height = 2400}) =>
    MirrorStreamConfig(
      codec: .h264,
      width: width,
      height: height,
      sps: Uint8List.fromList([0x67, 1, 2]),
      pps: Uint8List.fromList([0x68, 3]),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDecoderApi api;
  late VideoToolboxDecoder decoder;

  setUp(() {
    api = FakeDecoderApi();
    decoder = VideoToolboxDecoder(api: api);
  });

  tearDown(() => decoder.dispose());

  test('an H.264 stream creates one texture and hands over the parameter '
      'sets', () async {
    await decoder.configure(h264());
    await decoder.configure(h264(width: 2400, height: 1080));

    expect(api.calls, ['create', 'configure 3 2', 'configure 3 2']);
  });

  test('the picture is the texture once a frame was decoded, at the decoded '
      'size', () async {
    await decoder.configure(h264());
    final shown = <DecodedFrame>[];
    decoder.decoded.listen(shown.add);
    expect(decoder.picture.value, isNull);

    decoder.decode(
      MirrorFrame(data: Uint8List(4), ptsUs: 1000, keyframe: true),
    );
    decoder.onDecoded(1000, 1080, 2400);
    await pumpEventQueue();

    expect(api.calls.last, 'decode 1000 true');
    final picture = decoder.picture.value;
    expect(picture, isA<TexturePicture>());
    expect((picture as TexturePicture).textureId, 11);
    expect((picture.width, picture.height), (1080, 2400));
    expect(shown.single.ptsUs, 1000);

    decoder.onDecoded(2000, 2400, 1080);
    expect(decoder.picture.value?.width, 2400);
  });

  test('a stream without parameter sets, or one VideoToolbox refuses, '
      'throws', () async {
    await expectLater(
      decoder.configure(
        const MirrorStreamConfig(codec: .h264, width: 8, height: 8),
      ),
      throwsArgumentError,
    );

    api.refuseConfig = true;
    await expectLater(decoder.configure(h264()), throwsStateError);
  });

  test('a decoding error is reported', () async {
    await decoder.configure(h264());
    var errors = 0;
    decoder.errors.listen((_) => errors++);

    decoder.onDecodeError(-12909);
    await pumpEventQueue();

    expect(errors, 1);
  });

  test('a JPEG stream never touches the native decoder', () async {
    await decoder.configure(
      const MirrorStreamConfig(codec: .jpeg, width: 4, height: 2),
    );

    expect(api.calls, isEmpty);
  });

  test('dispose lets go of the texture', () async {
    await decoder.configure(h264());

    await decoder.dispose();

    expect(api.calls.last, 'dispose');
  });

  test('the window goes full screen through the plugin', () async {
    final window = MacMirrorWindow(api: api);

    expect(await window.canFullScreen(), isTrue);
    await window.setFullScreen(true);

    expect(await window.isFullScreen(), isTrue);
    expect(await const FixedMirrorWindow().canFullScreen(), isFalse);
  });
}
