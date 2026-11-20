import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:clipboard/services/services.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/clipboard.dart';

class _RecordingDragOut implements DragOut {
  final List<List<String>> fileDrags = [];
  final List<(String, bool)> textDrags = [];

  @override
  Future<bool> files(int viewId, List<String> paths) async {
    fileDrags.add(paths);
    return true;
  }

  @override
  Future<bool> promisedFiles(int viewId, List<PromisedFile> files) async =>
      false;

  @override
  Future<bool> text(int viewId, String text, {bool isLink = false}) async {
    textDrags.add((text, isLink));
    return true;
  }
}

ClipEntry _clip(
  String id, {
  ClipKind kind = .CLIP_KIND_TEXT,
  String text = '',
  List<int> image = const [],
  String mime = '',
}) => ClipEntry(
  item: ClipItem(
    id: id,
    kind: kind,
    text: text,
    image: image,
    imageMime: mime,
    createdAtMs: Int64(0),
  ),
  direction: .received,
  at: DateTime(2026, 11, 20),
);

void main() {
  late Directory cache;
  late _RecordingDragOut dragOut;
  late ClipDrags drags;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('clip_drags');
    dragOut = _RecordingDragOut();
    drags = ClipDrags(dragOut: dragOut, folder: () async => cache.path);
  });

  tearDown(() => cache.delete(recursive: true));

  test('text goes as text, a link as a link', () async {
    await drags.start(7, _clip('a', text: 'hello'), imageName: 'Image');
    await drags.start(
      7,
      _clip('b', kind: .CLIP_KIND_URL, text: 'https://example.com'),
      imageName: 'Image',
    );

    expect(dragOut.textDrags, [
      ('hello', false),
      ('https://example.com', true),
    ]);
  });

  test(
    'an image goes as a file named after it, and only the last stays',
    () async {
      await drags.start(
        7,
        _clip('one', kind: .CLIP_KIND_IMAGE, image: [1, 2], mime: 'image/png'),
        imageName: 'Image',
      );
      await drags.start(
        7,
        _clip('../two', kind: .CLIP_KIND_IMAGE, image: [3], mime: 'image/jpeg'),
        imageName: 'Image',
      );

      final [first, second] = [
        for (final paths in dragOut.fileDrags) paths.single,
      ];
      expect(first, endsWith('${Platform.pathSeparator}Image.png'));
      expect(second, endsWith('${Platform.pathSeparator}Image.jpg'));
      expect(second, startsWith(cache.path));
      expect(File(second).readAsBytesSync(), [3]);
      expect(File(first).existsSync(), isFalse);
    },
  );

  test('a cleared private clip has nothing to drag', () async {
    final cleared = _clip('a', text: 'secret').redact();

    expect(await drags.start(7, cleared, imageName: 'Image'), isFalse);
    expect(dragOut.textDrags, isEmpty);
  });

  test('names from another device stay inside the folder', () {
    expect(ClipDrags.folderNameOf('../../x'), '______x');
    expect(ClipDrags.folderNameOf('///'), 'clip');
    expect(ClipDrags.fileNameOf('a/b'), 'a b');
    expect(ClipDrags.extensionOf('image/HEIC'), 'heic');
  });
}
