import 'dart:io';

import 'package:drop/drop.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/transfers.dart';

void main() {
  group('FolderLabel', () {
    final posix = p.Context(style: p.Style.posix);

    test('reads a folder in the home folder from there', () {
      expect(
        FolderLabel.of(
          '/Users/me/Downloads/Ferret',
          home: '/Users/me',
          style: posix,
        ),
        'Downloads › Ferret',
      );
    });

    test('keeps the last two folders of anything else', () {
      expect(
        FolderLabel.of('/var/folders/x1/T/inbox/Ferret', style: posix),
        'inbox › Ferret',
      );
      expect(
        FolderLabel.of('Download/Ferret', style: posix),
        'Download › Ferret',
      );
      expect(FolderLabel.of('', style: posix), '');
    });
  });

  group('FileNames', () {
    test('keeps only the base name and strips unsafe characters', () {
      expect(FileNames.safe('../../etc/passwd'), 'passwd');
      expect(FileNames.safe(r'C:\Users\me\photo.jpg'), 'photo.jpg');
      expect(FileNames.safe('a<b>c:d"e|f?g*h.txt'), 'a_b_c_d_e_f_g_h.txt');
      expect(FileNames.safe('trailing. . '), 'trailing');
      expect(FileNames.safe('..'), 'file');
      expect(FileNames.safe(''), 'file');
      expect(FileNames.safe('CON.txt'), '_CON.txt');
    });

    test('shortens long names but keeps the extension', () {
      final long = '${'x' * 300}.pdf';

      final safe = FileNames.safe(long);

      expect(safe.length, 200);
      expect(safe, endsWith('.pdf'));
    });

    test('numbers alternatives before the extension', () {
      expect(FileNames.numbered('photo.jpg', 0), 'photo.jpg');
      expect(FileNames.numbered('photo.jpg', 1), 'photo (1).jpg');
      expect(FileNames.numbered('notes', 2), 'notes (2)');
      expect(FileNames.numbered('.bashrc', 1), '.bashrc (1)');
      expect(FileNames.numbered('logs.tar.gz', 1), 'logs (1).tar.gz');
    });
  });

  group('FolderPaths', () {
    test('cleans each part of a folder another device names', () {
      expect(FolderPaths.parts(''), isEmpty);
      expect(FolderPaths.parts('Photos/2024'), ['Photos', '2024']);
      expect(FolderPaths.parts(r'Photos\2024'), ['Photos', '2024']);
      expect(FolderPaths.parts('Photos//./2024/'), ['Photos', '2024']);
      expect(FolderPaths.parts('CON/aux.txt/a<b>'), [
        '_CON',
        '_aux.txt',
        'a_b_',
      ]);
      expect(FolderPaths.parts('trailing. /x'), ['trailing', 'x']);
      expect(FolderPaths.parts('${'x' * 300}/y')?.first.length, 200);
    });

    test('refuses folders that climb out or start at a root', () {
      for (final hostile in [
        '..',
        '../etc',
        'Photos/../../etc',
        'Photos/ .. /x',
        r'..\Windows',
        '/etc',
        r'\\server\share',
        'C:/Windows',
        r'c:\Windows',
        List.filled(40, 'a').join('/'),
        'a' * 2000,
      ]) {
        expect(FolderPaths.parts(hostile), isNull, reason: hostile);
      }
    });

    test('splits a name that carries its folder', () {
      expect(FolderPaths.split('a.jpg'), (folder: '', name: 'a.jpg'));
      expect(
        FolderPaths.split('Photos/2024/a.jpg'),
        (folder: 'Photos/2024', name: 'a.jpg'),
      );
      expect(
        FolderPaths.split(r'Photos\a.jpg'),
        (folder: 'Photos', name: 'a.jpg'),
      );
    });

    test('numbers folder copies as file managers do', () {
      expect(FileNames.numberedFolder('Photos', 0), 'Photos');
      expect(FileNames.numberedFolder('Photos', 1), 'Photos (2)');
      expect(FileNames.numberedFolder('v1.2', 2), 'v1.2 (3)');
    });
  });

  group('FolderReceiveStore', () {
    late Directory folder;

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('ferret_store');
    });

    tearDown(() => folder.delete(recursive: true));

    test('moves parts in place and never overwrites', () async {
      final store = FolderReceiveStore(() async => folder.path);
      final parts = await store.partsDirectory();
      await File(p.join(folder.path, 'a.txt')).writeAsString('old');
      await File(p.join(folder.path, 'a (1).txt')).writeAsString('older');
      final part = File(p.join(parts.path, 'x-0.part'));
      await part.writeAsString('new');

      final saved = await store.save(part, name: 'a.txt', mime: 'text/plain');

      expect(saved.name, 'a (2).txt');
      expect(await File(saved.location).readAsString(), 'new');
      expect(await File(p.join(folder.path, 'a.txt')).readAsString(), 'old');
      expect(part.existsSync(), isFalse);
    });

    test('two files saved at once get different names', () async {
      final store = FolderReceiveStore(() async => folder.path);
      final parts = await store.partsDirectory();
      final first = File(p.join(parts.path, '1.part'));
      final second = File(p.join(parts.path, '2.part'));
      await first.writeAsString('one');
      await second.writeAsString('two');

      final saved = await Future.wait([
        store.save(first, name: 'same.txt', mime: ''),
        store.save(second, name: 'same.txt', mime: ''),
      ]);

      expect(
        {for (final file in saved) file.name},
        {
          'same.txt',
          'same (1).txt',
        },
      );
    });
  });

  group('FolderReceiveStore folders', () {
    late Directory folder;
    late FolderReceiveStore store;

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('ferret_store');
      store = FolderReceiveStore(() async => folder.path);
    });

    tearDown(() => folder.delete(recursive: true));

    test('claims a new folder each time, never one that is there', () async {
      await File(p.join(folder.path, 'Notes')).writeAsString('a file');
      await Directory(p.join(folder.path, 'Photos (2)')).create();

      final names = [
        await store.reserveFolder('Photos'),
        await store.reserveFolder('Photos'),
        await store.reserveFolder('Notes'),
        await store.reserveFolder('.ferret-partial'),
      ];

      expect(names, [
        'Photos',
        'Photos (3)',
        'Notes (2)',
        '.ferret-partial (2)',
      ]);
    });

    test('saves into the folder and keeps the modified time', () async {
      final parts = await store.partsDirectory();
      final part = File(p.join(parts.path, '1.part'));
      await part.writeAsString('hi');
      final when = DateTime(2023, 3, 4, 5, 6, 7);

      final saved = await store.save(
        part,
        name: 'a.txt',
        mime: 'text/plain',
        folder: 'Photos/2024',
        modified: when,
      );

      expect(saved.location, p.join(folder.path, 'Photos', '2024', 'a.txt'));
      expect(File(saved.location).lastModifiedSync(), when);
    });

    test('never saves outside the receive folder', () async {
      final parts = await store.partsDirectory();
      final part = File(p.join(parts.path, '1.part'));
      await part.writeAsString('hi');

      await expectLater(
        store.save(part, name: 'a.txt', mime: '', folder: '../escape'),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        File(p.join(p.dirname(folder.path), 'escape')).existsSync(),
        isFalse,
      );
    });
  });

  group('FileHasher', () {
    test('hashes a file like sha256 does', () async {
      final folder = await Directory.systemTemp.createTemp('ferret_hash');
      addTearDown(() => folder.delete(recursive: true));
      final file = File(p.join(folder.path, 'abc.txt'));
      await file.writeAsString('abc');

      final hash = await FileHasher.hashFile(file.path);

      expect(
        [for (final byte in hash) byte.toRadixString(16).padLeft(2, '0')]
            .join(),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(FileHasher.same(hash, [...hash]), isTrue);
      expect(FileHasher.same(hash, [...hash.skip(1), 0]), isFalse);
    });
  });

  group('SpeedMeter', () {
    test('measures over the recent window only', () {
      var now = DateTime(2026);
      final meter = SpeedMeter(clock: () => now);

      meter.add(0);
      now = now.add(const Duration(seconds: 1));
      meter.add(1000);
      expect(meter.bytesPerSecond, 1000);

      now = now.add(const Duration(seconds: 10));
      meter.add(1000);
      now = now.add(const Duration(seconds: 1));
      meter.add(5000);
      expect(meter.bytesPerSecond, 4000);
    });
  });

  group('Transfer', () {
    test('progress and time left follow the bytes and speed', () {
      final transfer = sampleTransfer(
        bytesDone: 1024 * 1024,
        bytesPerSecond: 1024 * 1024,
      );

      expect(transfer.progress, 0.25);
      expect(transfer.eta, const Duration(seconds: 3));
    });

    test('only the sender can retry a declined transfer', () {
      final outgoing = sampleTransfer(
        direction: .outgoing,
        status: .failed,
        failure: .declined,
      );
      final incoming = sampleTransfer(status: .failed, failure: .declined);

      expect(outgoing.canRetry, isTrue);
      expect(incoming.canRetry, isFalse);
    });
  });

  group('TransferRegistry', () {
    test('keeps the newest finished transfers and every active one', () {
      final registry = TransferRegistry(keepFinished: 2);
      for (var index = 0; index < 4; index++) {
        registry.put(
          sampleTransfer(id: 'done$index', status: .done).copyWithStart(index),
        );
      }

      registry.put(sampleTransfer(id: 'active').copyWithStart(10));

      expect(registry.all.map((transfer) => transfer.id), [
        'active',
        'done3',
        'done2',
      ]);
    });
  });

  group('TransferTexts', () {
    final texts = TransferTexts(lookupDropLocalizations(const Locale('en')));

    test('describes sizes and times in plain words', () {
      expect(texts.size(512), '512 B');
      expect(texts.size(1536), '1.5 KB');
      expect(texts.size(5 * 1024 * 1024), '5 MB');
      expect(texts.size(3 * 1024 * 1024 * 1024), '3 GB');
      expect(texts.eta(const Duration(milliseconds: 200)), '1 s');
      expect(texts.eta(const Duration(minutes: 3)), '3 min');
      expect(texts.eta(const Duration(hours: 1, minutes: 5)), '1 h 5 min');
    });

    test('over a weak connection a transfer says why it crawls', () {
      final transfer = sampleTransfer(
        direction: .outgoing,
        bytesDone: 1024 * 1024,
        bytesPerSecond: 1024 * 1024,
      );

      expect(texts.progress(transfer), '1 MB of 4 MB · 3 s left');
      expect(
        texts.progress(transfer, isWeak: true),
        'Weak connection · 1 MB of 4 MB · 3 s left',
      );
      expect(
        texts.speed(transfer, isWeak: true),
        'Weak connection · 1 MB/s · 3 s left',
      );
    });

    test('a weak connection is only named while bytes move', () {
      final waiting = sampleTransfer(direction: .outgoing, status: .waiting);
      final done = sampleTransfer(status: .done, bytesDone: 4 * 1024 * 1024);

      expect(
        texts.progress(waiting, isWeak: true),
        texts.progress(waiting),
      );
      expect(texts.progress(done, isWeak: true), texts.progress(done));
    });

    test('names one file, many files, or the first line of text', () {
      expect(texts.title(sampleTransfer()), 'photo.jpg');
      expect(
        texts.title(
          sampleTransfer(
            files: const [
              TransferFile(name: 'a', size: 1),
              TransferFile(name: 'b', size: 1),
            ],
          ),
        ),
        '2 files',
      );
      expect(
        texts.title(sampleTransfer(files: const [], text: 'Hi\nthere')),
        'Hi',
      );
    });

    test('a folder reads as its name, with files and bytes', () {
      const files = [
        TransferFile(name: 'a.jpg', size: 1024, folder: 'Photos'),
        TransferFile(name: 'b.jpg', size: 1024, folder: 'Photos/2024'),
        TransferFile(name: 'c.jpg', size: 2048, folder: 'Photos/2024'),
      ];
      final folder = sampleTransfer(files: files, bytesDone: 2048 + 512);

      expect(texts.title(folder), 'Photos');
      expect(folder.filesDone, 2);
      expect(
        texts.status(folder),
        'From Pixel · 2 of 3 files · 2.5 KB of 4 KB',
      );
      expect(
        texts.status(
          sampleTransfer(
            files: [files.first],
            bytesDone: 0,
          ),
        ),
        'From Pixel · 0 of 1 file · 0 B of 1 KB',
      );
    });

    test('a received folder is found from its files', () {
      final folder = sampleTransfer(
        status: .done,
        files: const [
          TransferFile(
            name: 'b.jpg',
            size: 1,
            folder: 'Photos (2)/2024',
            location: '/home/me/Ferret/Photos (2)/2024/b.jpg',
          ),
        ],
      );
      final loose = sampleTransfer(status: .done);
      final mixed = sampleTransfer(
        files: const [
          TransferFile(name: 'a', size: 1, folder: 'A'),
          TransferFile(name: 'b', size: 1, folder: 'B'),
        ],
      );

      expect(folder.folderLocation, '/home/me/Ferret/Photos (2)');
      expect(loose.folderLocation, isNull);
      expect(mixed.isFolder, isFalse);
    });

    test('says why a transfer failed', () {
      expect(
        texts.status(sampleTransfer(status: .failed, failure: .checksum)),
        'The file arrived damaged. Try again to send it once more.',
      );
      expect(
        texts.status(
          sampleTransfer(direction: .outgoing, status: .waiting),
        ),
        'Waiting for Pixel to accept…',
      );
      expect(
        texts.status(
          sampleTransfer(
            direction: .outgoing,
            status: .failed,
            failure: .foldersUnsupported,
          ),
        ),
        "Pixel's Ferret is too old for folders. Update it, or send the files.",
      );
    });
  });
}

extension on Transfer {
  Transfer copyWithStart(int minutes) => Transfer(
    id: id,
    direction: direction,
    deviceId: deviceId,
    deviceName: deviceName,
    files: files,
    status: status,
    startedAt: startedAt.add(Duration(minutes: minutes)),
  );
}
