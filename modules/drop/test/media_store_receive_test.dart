import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drop/drop.dart';
import 'package:ferret_drop/ferret_drop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/drop.dart';

import 'support/files.dart';
import 'support/linked_devices.dart';

/// MediaStore Downloads in a folder: pending items sit in a hidden folder,
/// and only [publish] puts one under Download, as Android shows it.
class _FakeDownloads implements PendingDownloads {
  _FakeDownloads(this.root);

  final Directory root;
  final Map<String, ({File file, String folder, String name})> pending = {};
  final List<String> created = [];
  final List<String> deleted = [];
  final List<String> reopened = [];
  int _next = 0;

  Directory get downloads => Directory(p.join(root.path, 'Download'));

  /// Every file other apps can see under Download, by relative path.
  List<String> get visible => switch (downloads.existsSync()) {
    true => [
      for (final entity in downloads.listSync(recursive: true))
        if (entity is File) p.relative(entity.path, from: downloads.path),
    ]..sort(),
    false => [],
  };

  /// Takes every pending item away, as if someone deleted it.
  void vanish() {
    for (final item in pending.values) {
      item.file.deleteSync();
    }
  }

  @override
  Future<({String uri, PendingWriter writer})> create({
    required String folder,
    required String name,
    required String mime,
  }) async {
    final uri = 'content://media/external/downloads/${_next++}';
    final file = File(p.join(root.path, '.pending', '${_next - 1}'));
    await file.parent.create(recursive: true);
    pending[uri] = (file: file, folder: folder, name: name);
    created.add(uri);
    return (uri: uri, writer: await _writer(file, 0));
  }

  @override
  Future<PendingWriter?> open(String uri, int offset) async {
    final item = pending[uri];
    if (item == null || !item.file.existsSync()) {
      return null;
    }

    reopened.add(uri);
    return _writer(item.file, offset);
  }

  @override
  Future<int?> size(String uri) async {
    final file = pending[uri]?.file;
    if (file == null || !file.existsSync()) {
      return null;
    }

    return file.lengthSync();
  }

  @override
  Future<Uint8List> sha256(String uri) async => Uint8List.fromList(
    _sha256(await pending[uri]!.file.readAsBytes()),
  );

  @override
  Future<SavedFile> publish(String uri) async {
    final item = pending.remove(uri);
    if (item == null || !item.file.existsSync()) {
      throw const FileSystemException('Gone');
    }

    final target = File(p.join(downloads.path, item.folder, item.name));
    await target.parent.create(recursive: true);
    await item.file.rename(target.path);
    return SavedFile(location: uri, name: item.name);
  }

  @override
  Future<void> delete(String uri) async {
    deleted.add(uri);
    final item = pending.remove(uri);
    if (item != null && item.file.existsSync()) {
      await item.file.delete();
    }
  }

  Future<PendingWriter> _writer(File file, int offset) async {
    final open = await file.open(mode: FileMode.append);
    await open.truncate(offset);
    await open.setPosition(offset);
    return _FileWriter(open);
  }
}

List<int> _sha256(List<int> bytes) => sha256.convert(bytes).bytes;

class _FileWriter implements PendingWriter {
  _FileWriter(this._file);

  final RandomAccessFile _file;

  @override
  Future<void> write(List<int> bytes) => _file.writeFrom(bytes);

  @override
  Future<void> close() => _file.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory sources;
  late Directory app;
  late _FakeDownloads downloads;
  late LinkedDevices link;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_media_store');
    sources = await Directory(p.join(root.path, 'sources')).create();
    app = await Directory(p.join(root.path, 'app')).create();
    downloads = _FakeDownloads(
      await Directory(p.join(root.path, 'phone')).create(),
    );
    link = await LinkedDevices.start(
      laptopStore: folderStore(Directory(p.join(root.path, 'laptop'))),
      phoneStore: (_) => MediaStoreReceiveStore(
        plugin: FerretDrop(),
        folderName: () => 'Ferret',
        appDirectory: () async => app.path,
        downloads: downloads,
        downloadsDirectory: () async => downloads.downloads.path,
      ),
    );
  });

  tearDown(() => root.delete(recursive: true));

  Future<Transfer> send(List<File> files) async {
    final transfer = await link.laptop.feature.sendFiles(link.phone.id, [
      for (final file in files) file.path,
    ]);
    if (transfer == null) {
      throw StateError('Nothing to send');
    }

    return transfer;
  }

  Transfer? onPhone(String id) => link.phone.feature.registry[id];

  Transfer? onLaptop(String id) => link.laptop.feature.registry[id];

  Future<void> expectInDownloads(List<File> files, {String? folder}) async {
    for (final file in files) {
      final saved = File(
        p.joinAll([
          downloads.downloads.path,
          'Ferret',
          ?folder,
          p.basename(file.path),
        ]),
      );
      expect(
        await saved.readAsBytes(),
        await file.readAsBytes(),
        reason: p.basename(file.path),
      );
    }
  }

  test('files arrive straight in Downloads, with nothing copied at the end, '
      'and show only once they checked out', () async {
    final files = [
      await randomFile(sources, 'clip.mov', 20000),
      await randomFile(sources, 'notes.txt', 3000),
      await randomFile(sources, 'empty.bin', 0),
    ];
    final shownMidway = <List<String>>[];
    link.onDeliver = (from, message) {
      if (message is FileComplete) {
        shownMidway.add(downloads.visible);
      }
    };

    final sent = await send(files);
    await until(() => onPhone(sent.id)?.status == .done);

    await expectInDownloads(files);
    expect(downloads.visible, [
      'Ferret/clip.mov',
      'Ferret/empty.bin',
      'Ferret/notes.txt',
    ]);
    expect(shownMidway.first, isEmpty);
    expect(downloads.created, hasLength(3));
    expect(downloads.pending, isEmpty);
    expect(Directory(p.join(app.path, 'drop_partial')).existsSync(), isFalse);
    expect(
      onPhone(sent.id)!.files.map((file) => file.location),
      everyElement(startsWith('content://')),
    );
  });

  test('a folder lands under its own name in Downloads', () async {
    final folder = await Directory(p.join(sources.path, 'Photos')).create();
    final files = [
      await randomFile(folder, 'one.jpg', 2048),
      await randomFile(folder, 'two.jpg', 4096),
    ];

    final sent = await send([File(folder.path)]);
    await until(() => onPhone(sent.id)?.status == .done);

    await expectInDownloads(files, folder: 'Photos');
  });

  test(
    'a damaged file never shows in Downloads; Retry writes it again',
    () async {
      final files = [
        await randomFile(sources, 'a.bin', 5000),
        await randomFile(sources, 'b.bin', 5000),
      ];
      var corrupted = false;
      link.onDeliver = (from, message) {
        if (!corrupted && message is Chunk && message.fileIndex == 1) {
          corrupted = true;
          message.data[0] ^= 0xFF;
        }
      };

      final sent = await send(files);
      await until(() => onPhone(sent.id)?.status == .failed);
      expect(onPhone(sent.id)?.failure, TransferFailure.checksum);
      expect(downloads.visible, ['Ferret/a.bin']);
      expect(downloads.deleted, hasLength(1));
      expect(downloads.pending, isEmpty);

      link.onDeliver = null;
      await link.laptop.feature.retry(sent.id);
      await until(() => onPhone(sent.id)?.status == .done);
      await expectInDownloads(files);
    },
  );

  test('a dropped link resumes into the same pending file', () async {
    final file = await randomFile(sources, 'big.bin', 40000);
    var chunks = 0;
    link.onDeliver = (from, message) {
      if (message is Chunk && ++chunks == 12) {
        link.drop();
      }
    };

    final sent = await send([file]);
    await until(() => onLaptop(sent.id)?.isPaused ?? false);
    expect(downloads.visible, isEmpty);
    link
      ..onDeliver = null
      ..connect();
    await until(() => onPhone(sent.id)?.status == .done);

    await expectInDownloads([file]);
    expect(downloads.created, hasLength(1));
    expect(downloads.reopened, isNotEmpty);
  });

  test('when the pending file is gone after a drop, it starts over', () async {
    final file = await randomFile(sources, 'big.bin', 40000);
    var chunks = 0;
    link.onDeliver = (from, message) {
      if (message is Chunk && ++chunks == 12) {
        link.drop();
      }
    };

    final sent = await send([file]);
    await until(() => onLaptop(sent.id)?.isPaused ?? false);
    downloads.vanish();
    link
      ..onDeliver = null
      ..connect();
    await until(() => onPhone(sent.id)?.status == .done);

    await expectInDownloads([file]);
    expect(downloads.created, hasLength(2));
  });

  test('cancelling throws the pending files away', () async {
    final files = [
      await randomFile(sources, 'a.bin', 20000),
      await randomFile(sources, 'b.bin', 20000),
    ];
    var chunks = 0;
    String? id;
    link.onDeliver = (from, message) {
      if (message is Chunk && ++chunks == 8) {
        if (id case final sending?) {
          link.laptop.feature.cancel(sending).ignore();
        }
      }
    };

    final sent = await send(files);
    id = sent.id;
    await until(() => onPhone(sent.id)?.status == .cancelled);
    await until(() => downloads.pending.isEmpty);

    expect(downloads.visible, isEmpty);
    expect(downloads.deleted, isNotEmpty);
  });
}
