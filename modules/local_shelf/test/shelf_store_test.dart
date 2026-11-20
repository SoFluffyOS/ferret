import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late String cache;
  late DateTime now;

  ShelfStore storeOf({int limit = 50}) =>
      ShelfStore(cache, clock: () => now, limit: limit);

  File fileAt(String name, {String contents = 'hello'}) =>
      File(p.join(root.path, name))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(contents);

  setUp(() {
    root = Directory.systemTemp.createTempSync('shelf_test');
    cache = p.join(root.path, 'cache', 'shelf');
    now = DateTime(2026, 11, 20, 9);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('files are pointed at where they are, never copied', () async {
    final store = storeOf();
    await store.load();
    final report = fileAt('Report.pdf');

    final kept = await store.keepFiles([report.path], source: .dropped);

    expect(kept.single.path, report.path);
    expect(kept.single.kind, ShelfKind.file);
    expect(kept.single.isCached, isFalse);
    expect(Directory(p.join(cache, 'items')).existsSync(), isFalse);
  });

  test('pictures and folders get their kind', () async {
    final store = storeOf();
    await store.load();
    final photo = fileAt('IMG_2041.JPG');
    final folder = Directory(p.join(root.path, 'Trip'))..createSync();

    await store.keepFiles([photo.path, folder.path], source: .dropped);

    expect(
      [for (final item in store.items) item.kind],
      [
        ShelfKind.folder,
        ShelfKind.image,
      ],
    );
  });

  test('text and links are kept in files of their own', () async {
    final store = storeOf();
    await store.load();

    final text = await store.keepText(
      'Meeting notes\nsecond line',
      isLink: false,
      source: .copied,
    );
    final link = await store.keepText(
      'https://www.example.com/a',
      isLink: true,
      source: .copied,
    );

    expect(text?.kind, ShelfKind.text);
    expect(p.basename(text?.path ?? ''), 'Meeting notes.txt');
    expect(File(text?.path ?? '').readAsStringSync(), contains('second line'));
    expect(text?.name, 'Meeting notes second line');
    expect(link?.kind, ShelfKind.link);
    expect(link?.text, 'https://www.example.com/a');
    expect(File(link?.path ?? '').existsSync(), isTrue);
    expect(store.items.first.id, link?.id);
  });

  test('a picture copied as data is kept as a file', () async {
    final store = storeOf();
    await store.load();

    final image = await store.keepImage(
      Uint8List.fromList([1, 2, 3]),
      mime: 'image/jpeg',
      source: .copied,
      name: '',
    );

    expect(p.basename(image?.path ?? ''), 'Image.jpg');
    expect(File(image?.path ?? '').readAsBytesSync(), [1, 2, 3]);
  });

  test('the same thing again moves to the top instead of twice', () async {
    final store = storeOf();
    await store.load();
    await store.keepText('one', isLink: false, source: .copied);
    await store.keepText('two', isLink: false, source: .copied);

    now = now.add(const Duration(minutes: 1));
    await store.keepText('one', isLink: false, source: .dropped);

    expect([for (final item in store.items) item.name], ['one', 'two']);
    expect(store.items.first.source, ShelfSource.dropped);
    expect(store.items.first.addedAt, now);
  });

  test('beyond the limit copies go oldest first, drops stay', () async {
    final store = storeOf(limit: 3);
    await store.load();
    await store.keepText('dropped', isLink: false, source: .dropped);
    final oldCopy = await store.keepText(
      'old copy',
      isLink: false,
      source: .copied,
    );
    await store.keepText('copy 2', isLink: false, source: .copied);
    await store.keepText('copy 3', isLink: false, source: .copied);

    expect(
      [for (final item in store.items) item.name],
      [
        'copy 3',
        'copy 2',
        'dropped',
      ],
    );
    expect(File(oldCopy?.path ?? '').existsSync(), isFalse);
  });

  test('drops are never pushed out, even past the limit', () async {
    final store = storeOf(limit: 2);
    await store.load();
    for (final name in ['a', 'b', 'c']) {
      await store.keepText(name, isLink: false, source: .dropped);
    }

    expect(store.items, hasLength(3));
  });

  test('the shelf comes back after a restart', () async {
    final first = storeOf();
    await first.load();
    final report = fileAt('Report.pdf');
    await first.keepFiles([report.path], source: .dropped);
    await first.keepText('note', isLink: false, source: .copied);

    final second = storeOf();
    await second.load();

    expect(
      [for (final item in second.items) item.name],
      [
        'note',
        'Report.pdf',
      ],
    );
    expect(second.items.last.source, ShelfSource.dropped);
  });

  test('a moved file shows as missing; a lost kept file goes', () async {
    final store = storeOf();
    await store.load();
    final report = fileAt('Report.pdf');
    await store.keepFiles([report.path], source: .dropped);
    final note = await store.keepText('note', isLink: false, source: .copied);

    report.deleteSync();
    Directory(p.dirname(note?.path ?? '')).deleteSync(recursive: true);
    await store.refresh();

    expect(store.items.single.name, 'Report.pdf');
    expect(store.items.single.isMissing, isTrue);
  });

  test('removing deletes only what Ferret kept', () async {
    final store = storeOf();
    await store.load();
    final report = fileAt('Report.pdf');
    final kept = await store.keepFiles([report.path], source: .dropped);
    final note = await store.keepText('note', isLink: false, source: .copied);

    await store.remove([kept.single.id, note?.id ?? '']);

    expect(store.items, isEmpty);
    expect(report.existsSync(), isTrue);
    expect(File(note?.path ?? '').existsSync(), isFalse);
  });

  test('a file dropped from a temporary place is copied in', () async {
    final store = storeOf();
    await store.load();
    final promised = fileAt(p.join('ferret-drops', 'abc', 'IMG_1.jpg'));

    final kept = await store.keepFiles([promised.path], source: .dropped);
    promised.deleteSync();

    expect(kept.single.isCached, isTrue);
    expect(p.isWithin(cache, kept.single.path), isTrue);
    expect(File(kept.single.path).readAsStringSync(), 'hello');
  });

  test('clear takes everything off', () async {
    final store = storeOf();
    await store.load();
    await store.keepText('note', isLink: false, source: .copied);

    await store.clear();

    final reloaded = storeOf();
    await reloaded.load();

    expect(store.items, isEmpty);
    expect(reloaded.items, isEmpty);
  });
}
