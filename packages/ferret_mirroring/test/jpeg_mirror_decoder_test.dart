import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

MirrorFrame frame(int ptsUs, [List<int> bytes = const [1]]) => MirrorFrame(
  data: Uint8List.fromList(bytes),
  ptsUs: ptsUs,
  keyframe: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decodes a real JPEG with Flutter\'s own codec', () async {
    final jpeg = File('test/fixtures/red_4x2.jpg').readAsBytesSync();
    final decoder = JpegMirrorDecoder();
    final decoded = decoder.decoded.first;
    await decoder.configure(
      const MirrorStreamConfig(codec: .jpeg, width: 4, height: 2),
    );

    decoder.decode(MirrorFrame(data: jpeg, ptsUs: 42, keyframe: true));
    final shown = await decoded;

    expect((shown.ptsUs, shown.width, shown.height), (42, 4, 2));
    final picture = decoder.picture.value;
    expect(picture, isA<ImagePicture>());
    expect((picture?.width, picture?.height), (4, 2));
    await decoder.dispose();
  });

  test('only takes JPEG streams', () async {
    final decoder = JpegMirrorDecoder();

    await expectLater(
      decoder.configure(
        const MirrorStreamConfig(codec: .h264, width: 4, height: 2),
      ),
      throwsUnsupportedError,
    );
    await decoder.dispose();
  });

  test('when pictures arrive faster than they decode, only the newest '
      'waits', () async {
    final image = await createTestImage(width: 4, height: 2);
    final gates = <Completer<ui.Image>>[];
    final asked = <int>[];
    final decoder = JpegMirrorDecoder(
      decodeImage: (bytes) {
        asked.add(bytes.single);
        final gate = Completer<ui.Image>();
        gates.add(gate);
        return gate.future;
      },
    );
    final shown = <int>[];
    decoder.decoded.listen((frame) => shown.add(frame.ptsUs));

    decoder
      ..decode(frame(1, [1]))
      ..decode(frame(2, [2]))
      ..decode(frame(3, [3]));
    expect(asked, [1]);

    gates.removeAt(0).complete(image.clone());
    await pumpEventQueue();
    expect(asked, [1, 3], reason: 'the second picture was skipped');

    gates.removeAt(0).complete(image.clone());
    await pumpEventQueue();
    expect(shown, [1, 3]);
    await decoder.dispose();
    image.dispose();
  });

  test('a picture that isn\'t a JPEG is an error, and the next one still '
      'shows', () async {
    final image = await createTestImage(width: 4, height: 2);
    var fail = true;
    final decoder = JpegMirrorDecoder(
      decodeImage: (_) async {
        if (fail) {
          throw const FormatException('not a picture');
        }

        return image.clone();
      },
    );
    var errors = 0;
    decoder.errors.listen((_) => errors++);

    decoder.decode(frame(1));
    await pumpEventQueue();
    expect(errors, 1);
    expect(decoder.picture.value, isNull);

    fail = false;
    decoder.decode(frame(2));
    await pumpEventQueue();
    expect(decoder.picture.value, isA<ImagePicture>());
    await decoder.dispose();
    image.dispose();
  });

  test('nothing shows after dispose', () async {
    final image = await createTestImage(width: 4, height: 2);
    final gate = Completer<ui.Image>();
    final decoder = JpegMirrorDecoder(decodeImage: (_) => gate.future);

    decoder.decode(frame(1));
    final picture = decoder.picture;
    await decoder.dispose();
    gate.complete(image.clone());
    await pumpEventQueue();

    expect(() => picture.value, returnsNormally);
    decoder.decode(frame(2));
    image.dispose();
  });
}
