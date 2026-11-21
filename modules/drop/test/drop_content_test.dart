import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drop/drop.dart';
import 'package:ferret_drop/ferret_drop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/drop.dart';

import 'support/files.dart';
import 'support/linked_devices.dart';

/// Shared files read straight from another app's `content://` URIs.
void main() {
  late Directory root;
  late Directory phoneInbox;
  late _FakeContent content;
  late LinkedDevices link;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_drop_content');
    phoneInbox = Directory(p.join(root.path, 'phone'));
    content = _FakeContent(root);
    link = await LinkedDevices.start(
      laptopStore: folderStore(Directory(p.join(root.path, 'laptop'))),
      phoneStore: folderStore(phoneInbox),
      laptopSources: SendSources(content: content),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Transfer? onPhone(String id) => link.phone.feature.registry[id];

  Transfer? onLaptop(String id) => link.laptop.feature.registry[id];

  test('sends a shared URI as it reads it, then lets go of it', () async {
    final bytes = content.add('content://docs/1', 'clip.mp4', 20 * 1024 + 3);

    final sent = await link.laptop.feature.sendFiles(link.phone.id, [
      'content://docs/1',
    ], temporary: true);
    await until(() => onLaptop(sent!.id)?.status == .done);
    await until(() => onPhone(sent!.id)?.status == .done);

    final file = sent!.files.single;
    expect(file.name, 'clip.mp4');
    expect(file.size, bytes.length);
    expect(file.mime, 'video/mp4');
    expect(file.location, 'content://docs/1');
    expect(
      await File(p.join(phoneInbox.path, 'clip.mp4')).readAsBytes(),
      bytes,
    );
    expect(content.opened, ['content://docs/1']);
    expect(content.released, ['content://docs/1']);
    expect(content.copied, isEmpty);
  });

  test('resumes after a dropped link by reading the URI again', () async {
    final bytes = content.add('content://docs/2', 'big.bin', 20 * 1024);
    var chunks = 0;
    link.onDeliver = (from, message) {
      if (message is Chunk && ++chunks == 9) {
        link
          ..onDeliver = null
          ..drop();
      }
    };

    final sent = await link.laptop.feature.sendFiles(link.phone.id, [
      'content://docs/2',
    ]);
    await until(() => onLaptop(sent!.id)?.isPaused ?? false);
    await until(() => onPhone(sent!.id)?.isPaused ?? false);

    link.connect();
    await until(() => onPhone(sent!.id)?.status == .done);
    await until(() => onLaptop(sent!.id)?.status == .done);

    final resume = link.phone.session?.sent.whereType<ResumeRequest>().single;
    final resent = link.laptop.session?.sent.whereType<Chunk>().toList();
    expect(resume?.offset.toInt(), greaterThan(0));
    expect(resent?.first.offset, resume?.offset);
    expect(content.opened, ['content://docs/2', 'content://docs/2']);
    expect(await File(p.join(phoneInbox.path, 'big.bin')).readAsBytes(), bytes);
    expect(content.released, isEmpty);
  });

  test('an app that does not say the size is copied first', () async {
    final bytes = content.add(
      'content://docs/3',
      'stream.txt',
      5000,
      reportsSize: false,
    );

    final sent = await link.laptop.feature.sendFiles(link.phone.id, [
      'content://docs/3',
    ], temporary: true);
    await until(() => onPhone(sent!.id)?.status == .done);

    expect(content.copied, ['content://docs/3']);
    expect(content.opened, isEmpty);
    expect(
      await File(p.join(phoneInbox.path, 'stream.txt')).readAsBytes(),
      bytes,
    );
    await until(() => onLaptop(sent!.id)?.status == .done);
    expect(File(sent!.files.single.location!).existsSync(), isFalse);
  });

  test('a URI that can no longer be read stops the send', () async {
    content.add('content://docs/4', 'gone.bin', 4000);
    final sent = await link.laptop.feature.sendFiles(link.phone.id, [
      'content://docs/4',
    ]);
    content.unreadable.add('content://docs/4');

    await until(() => onLaptop(sent!.id)?.status == .failed);
    expect(onLaptop(sent!.id)?.failure, TransferFailure.sourceChanged);
  });

  test('a URI the app no longer describes is left out', () async {
    final sent = await link.laptop.feature.sendFiles(link.phone.id, [
      'content://docs/missing',
    ]);

    expect(sent, isNull);
  });
}

class _FakeContent implements ContentSource {
  _FakeContent(this._cache);

  final Directory _cache;
  final Map<String, ({String name, Uint8List bytes, bool reportsSize})> _items =
      {};
  final List<String> opened = [];
  final List<String> released = [];
  final List<String> copied = [];
  final Set<String> unreadable = {};

  Uint8List add(String uri, String name, int size, {bool reportsSize = true}) {
    final random = Random(size);
    final bytes = Uint8List.fromList([
      for (var i = 0; i < size; i++) random.nextInt(256),
    ]);
    _items[uri] = (name: name, bytes: bytes, reportsSize: reportsSize);
    return bytes;
  }

  @override
  Future<ContentInfo?> describe(String uri) async {
    final item = _items[uri];
    if (item == null) {
      return null;
    }

    return ContentInfo(
      name: item.name,
      size: item.reportsSize ? item.bytes.length : -1,
      mime: '',
    );
  }

  @override
  Future<ContentReader> open(String uri) async {
    final item = _items[uri];
    if (item == null || unreadable.contains(uri)) {
      throw FileSystemException('Permission gone', uri);
    }

    opened.add(uri);
    return _FakeReader(item.bytes);
  }

  @override
  Future<String?> copy(String uri) async {
    final item = _items[uri];
    if (item == null) {
      return null;
    }

    copied.add(uri);
    final file = File(p.join(_cache.path, item.name));
    await file.writeAsBytes(item.bytes);
    return file.path;
  }

  @override
  Future<void> release(String uri) async => released.add(uri);
}

/// Hands out at most 700 bytes per read, like a pipe from another app.
class _FakeReader implements ContentReader {
  _FakeReader(this._bytes);

  final Uint8List _bytes;
  int _at = 0;

  @override
  int? get length => null;

  @override
  Future<Uint8List> read(int max) async {
    final end = min(_bytes.length, _at + min<int>(max, 700));
    final slice = Uint8List.sublistView(_bytes, _at, end);
    _at = end;
    return slice;
  }

  @override
  Future<void> close() async {}
}
