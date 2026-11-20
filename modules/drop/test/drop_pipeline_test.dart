import 'dart:async';
import 'dart:io';

import 'package:drop/drop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/drop.dart';

import 'support/files.dart';
import 'support/linked_devices.dart';

/// Saves like Android's MediaStore: each verified file takes a while to
/// copy into place, and saves can run side by side.
class _SlowStore extends FolderReceiveStore {
  _SlowStore(Directory folder, {this.delay = Duration.zero})
    : super(() async => folder.path);

  Duration delay;
  int running = 0;
  int mostAtOnce = 0;

  /// Names whose save throws, like a full disk.
  final Set<String> failing = {};

  @override
  Future<ReceivedFile> save(
    File part, {
    required String name,
    required String mime,
    String? folder,
    DateTime? modified,
  }) async {
    running++;
    if (running > mostAtOnce) {
      mostAtOnce = running;
    }

    try {
      await Future<void>.delayed(delay);
      if (failing.contains(name)) {
        throw const FileSystemException('No space left on device');
      }

      return await super.save(
        part,
        name: name,
        mime: mime,
        folder: folder,
        modified: modified,
      );
    } finally {
      running--;
    }
  }

  @override
  Future<bool> copiesOnSave() async => true;
}

void main() {
  late Directory root;
  late Directory sources;
  late Directory phoneInbox;
  late _SlowStore phoneStore;
  late LinkedDevices link;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_drop_pipeline');
    sources = await Directory(p.join(root.path, 'sources')).create();
    phoneInbox = Directory(p.join(root.path, 'phone'));
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<void> startLink({
    Duration saveDelay = Duration.zero,
    Duration latency = Duration.zero,
    int chunkSize = 1024,
    int ackEvery = 4,
  }) async {
    phoneStore = _SlowStore(phoneInbox, delay: saveDelay);
    link = await LinkedDevices.start(
      laptopStore: folderStore(Directory(p.join(root.path, 'laptop'))),
      phoneStore: (_) => phoneStore,
      chunkSize: chunkSize,
      ackEvery: ackEvery,
    );
    link.latency = latency;
  }

  Future<List<File>> smallFiles(int count, {int size = 3000}) async {
    final folder = await Directory(p.join(sources.path, 'Small')).create();
    return [
      for (var index = 0; index < count; index++)
        await randomFile(folder, 'file_$index.bin', size + index),
    ];
  }

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

  Future<void> expectSaved(List<File> files) async {
    for (final file in files) {
      final saved = File(p.join(phoneInbox.path, p.basename(file.path)));
      expect(
        await saved.readAsBytes(),
        await file.readAsBytes(),
        reason: p.basename(file.path),
      );
    }

    expect(partFiles(phoneInbox), isEmpty);
  }

  test('many small files over a slow link: the next file goes while the '
      'last one is checked and saved', () async {
    const count = 120;
    const saveDelay = Duration(milliseconds: 30);
    await startLink(
      saveDelay: saveDelay,
      latency: const Duration(milliseconds: 3),
      chunkSize: DropSender.defaultChunkSize,
      ackEvery: DropSender.defaultAckEvery,
    );
    final files = await smallFiles(count, size: 20 * 1024);

    final clock = Stopwatch()..start();
    final sent = await send(files);
    await until(
      () => onLaptop(sent.id)?.status == .done,
      timeout: const Duration(seconds: 60),
    );
    clock.stop();

    final bytes = files.fold(0, (sum, file) => sum + file.lengthSync());
    final megabits = bytes * 8 / clock.elapsedMicroseconds;
    // ignore: avoid_print
    print(
      'Pipelined: $count files, ${bytes ~/ 1024} KB in '
      '${clock.elapsedMilliseconds} ms ($megabits Mbit/s), '
      'up to ${phoneStore.mostAtOnce} saves at once',
    );
    expect(onPhone(sent.id)?.status, TransferStatus.done);
    await expectSaved(files);
    // One file after the other can't beat its saves end to end.
    expect(clock.elapsed, lessThan(saveDelay * count * 0.6));
    expect(
      phoneStore.mostAtOnce,
      inInclusiveRange(2, DropReceiver.savesAtOnce),
    );
  });

  test(
    'a file is announced complete before the one before it is verified',
    () async {
      await startLink(saveDelay: const Duration(milliseconds: 20));
      final files = await smallFiles(5);
      final order = <String>[];
      link.onDeliver = (from, message) {
        if (message is FileComplete) {
          order.add('complete ${message.fileIndex}');
        }
      };
      final verified = <int>[];
      final subscription = link.phone.feature.updates.listen((transfer) {
        final saved = transfer.files.where((file) => file.location != null);
        while (verified.length < saved.length) {
          order.add('saved ${verified.length}');
          verified.add(verified.length);
        }
      });
      addTearDown(subscription.cancel);

      final sent = await send(files);
      await until(() => onLaptop(sent.id)?.status == .done);

      expect(
        order.indexOf('complete 1'),
        lessThan(order.indexOf('saved 0')),
        reason: '$order',
      );
      await expectSaved(files);
    },
  );

  test('a link that drops while files are being saved resumes without '
      'sending any file twice', () async {
    await startLink(saveDelay: const Duration(milliseconds: 15));
    final files = await smallFiles(12);
    var completes = 0;
    link.onDeliver = (from, message) {
      if (message is FileComplete && ++completes == 6) {
        link.drop();
      }
    };

    final sent = await send(files);
    await until(() => onLaptop(sent.id)?.isPaused ?? false);
    link
      ..onDeliver = null
      ..connect();
    await until(() => onLaptop(sent.id)?.status == .done);
    await until(() => onPhone(sent.id)?.status == .done);

    await expectSaved(files);
    final names = phoneInbox
        .listSync()
        .whereType<File>()
        .map((file) => p.basename(file.path))
        .toList();
    expect(names, hasLength(files.length), reason: '$names');
  });

  test('a damaged file stops the files after it, and Retry fixes it', () async {
    await startLink();
    final files = await smallFiles(8);
    var corrupted = false;
    link.onDeliver = (from, message) {
      if (!corrupted &&
          message is Chunk &&
          message.fileIndex == 3 &&
          message.data.isNotEmpty) {
        corrupted = true;
        message.data[0] ^= 0xFF;
      }
    };

    final sent = await send(files);
    await until(() => onLaptop(sent.id)?.status == .failed);
    expect(onLaptop(sent.id)?.failure, TransferFailure.checksum);
    await until(() => onPhone(sent.id)?.status == .failed);
    expect(onPhone(sent.id)?.failure, TransferFailure.checksum);

    link.onDeliver = null;
    await link.laptop.feature.retry(sent.id);
    await until(() => onLaptop(sent.id)?.status == .done);
    await until(() => onPhone(sent.id)?.status == .done);
    await expectSaved(files);
  });

  test(
    'a save that fails stops the transfer as storage, on both sides',
    () async {
      await startLink(saveDelay: const Duration(milliseconds: 5));
      final files = await smallFiles(8);
      phoneStore.failing.add('file_2.bin');

      final sent = await send(files);
      await until(() => onLaptop(sent.id)?.status == .failed);
      expect(onLaptop(sent.id)?.failure, TransferFailure.storage);
      await until(() => onPhone(sent.id)?.status == .failed);
      expect(onPhone(sent.id)?.failure, TransferFailure.storage);

      phoneStore.failing.clear();
      await link.laptop.feature.retry(sent.id);
      await until(() => onLaptop(sent.id)?.status == .done);
      await until(() => onPhone(sent.id)?.status == .done);
      await expectSaved(files);
    },
  );

  test('cancelling while files are saved leaves no parts behind', () async {
    await startLink(saveDelay: const Duration(milliseconds: 40));
    final files = await smallFiles(10);
    var completes = 0;
    String? id;
    link.onDeliver = (from, message) {
      if (message is FileComplete && ++completes == 4) {
        if (id case final sending?) {
          unawaited(link.laptop.feature.cancel(sending));
        }
      }
    };

    final sent = await send(files);
    id = sent.id;
    await until(() => onPhone(sent.id)?.status == .cancelled);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(onLaptop(sent.id)?.status, TransferStatus.cancelled);
    expect(onPhone(sent.id)?.status, TransferStatus.cancelled);
    expect(partFiles(phoneInbox), isEmpty);
  });
}
