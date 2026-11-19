import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photos/photos.dart';

void main() {
  late Directory root;

  setUp(() async => root = await Directory.systemTemp.createTemp('photos'));
  tearDown(() async => root.delete(recursive: true));

  Uint8List bytes(int size, [int fill = 1]) =>
      Uint8List.fromList(List.filled(size, fill));

  test('a thumbnail written is read back, by size', () async {
    final cache = ThumbnailCache(root.path);
    await cache.write('pixel', 'i:1', 320, bytes(10, 7));

    expect(await cache.read('pixel', 'i:1', 320), bytes(10, 7));
    expect(await cache.read('pixel', 'i:1', 1600), isNull);
    expect(await cache.read('ipad', 'i:1', 320), isNull);
  });

  test('the least recently used go first once over the cap', () async {
    final cache = ThumbnailCache(root.path, maxBytes: 30);
    await cache.write('pixel', 'a', 320, bytes(10));
    await cache.write('pixel', 'b', 320, bytes(10));
    await cache.write('pixel', 'c', 320, bytes(10));
    await cache.read('pixel', 'a', 320);

    await cache.write('pixel', 'd', 320, bytes(10));

    expect(await cache.totalBytes, 30);
    expect(await cache.read('pixel', 'b', 320), isNull);
    expect(await cache.read('pixel', 'a', 320), isNotNull);
    expect(await cache.read('pixel', 'd', 320), isNotNull);
  });

  test('a new cache finds what an earlier one kept, and trims it', () async {
    final first = ThumbnailCache(root.path);
    await first.write('pixel', 'a', 320, bytes(10));
    await first.write('pixel', 'b', 320, bytes(10));

    final second = ThumbnailCache(root.path, maxBytes: 10);

    expect(await second.totalBytes, 10);
  });

  test('unpairing a phone deletes its thumbnails only', () async {
    final cache = ThumbnailCache(root.path);
    await cache.write('pixel', 'a', 320, bytes(10));
    await cache.write('ipad', 'a', 320, bytes(10));

    await cache.keepOnly({'ipad'});

    expect(await cache.read('pixel', 'a', 320), isNull);
    expect(await cache.read('ipad', 'a', 320), isNotNull);
    expect(await cache.totalBytes, 10);

    await cache.clearDevice('ipad');
    expect(await cache.totalBytes, 0);
    expect(root.listSync(), isEmpty);
  });
}
