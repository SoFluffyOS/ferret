import 'dart:io';

import 'package:drop/drop.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/drop.dart';
import 'package:protocol/protocol.dart' hide Platform;

import 'support/files.dart';
import 'support/linked_devices.dart';

void main() {
  late Directory root;
  late Directory sources;
  late Directory laptopInbox;
  late Directory phoneInbox;
  late LinkedDevices link;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_drop_test');
    sources = await Directory(p.join(root.path, 'sources')).create();
    laptopInbox = Directory(p.join(root.path, 'laptop'));
    phoneInbox = Directory(p.join(root.path, 'phone'));
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<void> startLink({
    Map<String, Object?> phoneSettings = const {},
  }) async {
    link = await LinkedDevices.start(
      laptopStore: folderStore(laptopInbox),
      phoneStore: folderStore(phoneInbox),
      phoneSettings: phoneSettings,
    );
  }

  Transfer? onPhone(String id) => link.phone.feature.registry[id];

  Transfer? onLaptop(String id) => link.laptop.feature.registry[id];

  Future<Transfer> send(List<File> files) async {
    final transfer = await link.laptop.feature.sendFiles(
      link.phone.id,
      [for (final file in files) file.path],
    );
    if (transfer == null) {
      throw StateError('Nothing to send');
    }

    return transfer;
  }

  test('sends a multi-chunk file and saves it once the hash matches', () async {
    await startLink();
    final source = await randomFile(sources, 'photo.jpg', 10 * 1024 + 7);

    final sent = await send([source]);
    await until(() => onPhone(sent.id)?.status == .done);
    await until(() => onLaptop(sent.id)?.status == .done);

    final received = onPhone(sent.id);
    final saved = File(p.join(phoneInbox.path, 'photo.jpg'));
    expect(received?.files.single.location, saved.path);
    expect(received?.progress, 1);
    expect(await saved.readAsBytes(), await source.readAsBytes());
    expect(partFiles(phoneInbox), isEmpty);
    final chunks = link.laptop.session?.sent.whereType<Chunk>() ?? [];
    expect(chunks.length, 11);
  });

  test('sends several files, including an empty one', () async {
    await startLink();
    final first = await randomFile(sources, 'a.bin', 3000);
    final empty = await randomFile(sources, 'empty.txt', 0);

    final sent = await send([first, empty]);
    await until(() => onPhone(sent.id)?.status == .done);

    expect(
      await File(p.join(phoneInbox.path, 'a.bin')).readAsBytes(),
      await first.readAsBytes(),
    );
    expect(File(p.join(phoneInbox.path, 'empty.txt')).lengthSync(), 0);
  });

  test('resumes from the offset after the session drops', () async {
    await startLink();
    final source = await randomFile(sources, 'movie.mp4', 20 * 1024);
    var chunks = 0;
    link.onDeliver = (from, message) {
      if (message is Chunk && ++chunks == 9) {
        link
          ..onDeliver = null
          ..drop();
      }
    };

    final sent = await send([source]);
    await until(() => onLaptop(sent.id)?.status == .failed);
    await until(() => onPhone(sent.id)?.status == .failed);
    expect(onLaptop(sent.id)?.failure, TransferFailure.disconnected);
    expect(onPhone(sent.id)?.failure, TransferFailure.disconnected);
    expect(partFiles(phoneInbox), isNotEmpty);
    expect(onLaptop(sent.id)?.isPaused, isTrue);
    expect(onPhone(sent.id)?.isPaused, isTrue);

    link.connect();
    await until(() => onPhone(sent.id)?.status == .done);
    await until(() => onLaptop(sent.id)?.status == .done);

    final resume = link.phone.session?.sent.whereType<ResumeRequest>().single;
    expect(resume?.fileIndex, 0);
    expect(resume?.offset.toInt(), 8 * 1024);
    final resent = link.laptop.session?.sent.whereType<Chunk>().toList();
    expect(resent?.first.offset.toInt(), 8 * 1024);
    expect(resent?.length, 12);
    expect(
      await File(p.join(phoneInbox.path, 'movie.mp4')).readAsBytes(),
      await source.readAsBytes(),
    );
  });

  test('a send to a device that is away goes once it is back', () async {
    await startLink();
    final source = await randomFile(sources, 'notes.pdf', 5000);
    link.drop();

    final sent = await send([source]);
    await until(() => onLaptop(sent.id)?.isPaused ?? false);
    expect(onLaptop(sent.id)?.failure, TransferFailure.notConnected);

    link.connect();
    await until(() => onPhone(sent.id)?.status == .done);
    await until(() => onLaptop(sent.id)?.status == .done);
    expect(
      await File(p.join(phoneInbox.path, 'notes.pdf')).readAsBytes(),
      await source.readAsBytes(),
    );
  });

  test(
    'an offer cut off before its answer is asked again on reconnect',
    () async {
      await startLink(phoneSettings: {DropSettings.autoAccept: false});
      final source = await randomFile(sources, 'plan.key', 2000);

      final sent = await send([source]);
      await until(() => onPhone(sent.id)?.needsAnswer ?? false);
      link.drop();
      await until(() => onLaptop(sent.id)?.isPaused ?? false);
      expect(onPhone(sent.id)?.isPaused, isTrue);

      link.connect();
      await until(() => onPhone(sent.id)?.needsAnswer ?? false);
      expect(onLaptop(sent.id)?.status, TransferStatus.waiting);
      link.phone.feature.answer(sent.id, accept: true);
      await until(() => onLaptop(sent.id)?.status == .done);
      expect(
        await File(p.join(phoneInbox.path, 'plan.key')).readAsBytes(),
        await source.readAsBytes(),
      );
    },
  );

  test('a cancelled offer is not asked again', () async {
    await startLink(phoneSettings: {DropSettings.autoAccept: false});
    final source = await randomFile(sources, 'old.zip', 2000);

    final sent = await send([source]);
    await until(() => onPhone(sent.id)?.needsAnswer ?? false);
    link.drop();
    await until(() => onPhone(sent.id)?.isPaused ?? false);
    await link.phone.feature.cancel(sent.id);
    expect(onPhone(sent.id)?.status, TransferStatus.cancelled);

    link.connect();
    await until(
      () =>
          onLaptop(sent.id)?.status == .failed &&
          onLaptop(sent.id)?.failure == TransferFailure.declined,
    );
    expect(onPhone(sent.id)?.needsAnswer, isFalse);
  });

  test('offering the same transfer again answers where to continue', () async {
    await startLink();
    final source = await randomFile(sources, 'notes.pdf', 6 * 1024);
    var chunks = 0;
    link.onDeliver = (from, message) {
      if (message is Chunk && ++chunks == 4) {
        link
          ..onDeliver = null
          ..drop();
      }
    };

    final sent = await send([source]);
    await until(() => onPhone(sent.id)?.status == .failed);

    final fromLaptop = LinkedSession(link, from: link.phone, to: link.laptop);
    final answer = await link.phone.feature.onEnvelope(
      fromLaptop,
      Envelope(
        feature: DropFeature.featureId,
        type: TransferOffer().payloadType,
        payload: TransferOffer(
          transferId: sent.id,
          files: [FileInfo(name: 'notes.pdf', size: Int64(6 * 1024))],
        ).toPayload(),
        expectsReply: true,
      ),
    );

    expect(answer, isA<TransferAnswer>());
    final resume = answer as TransferAnswer;
    expect(resume.accepted, isTrue);
    expect(resume.fileIndex, 0);
    expect(resume.offset.toInt(), 3 * 1024);
    expect(onPhone(sent.id)?.status, TransferStatus.transferring);
  });

  test('never overwrites: a taken name becomes "name (1).ext"', () async {
    await startLink();
    await phoneInbox.create(recursive: true);
    final existing = File(p.join(phoneInbox.path, 'report.txt'));
    await existing.writeAsString('keep me');
    final source = await randomFile(sources, 'report.txt', 2048);

    final sent = await send([source]);
    await until(() => onPhone(sent.id)?.status == .done);

    expect(await existing.readAsString(), 'keep me');
    expect(onPhone(sent.id)?.files.single.name, 'report (1).txt');
    expect(
      await File(p.join(phoneInbox.path, 'report (1).txt')).readAsBytes(),
      await source.readAsBytes(),
    );
  });

  test('cancelling mid-way stops both sides and deletes the part', () async {
    await startLink();
    final source = await randomFile(sources, 'big.iso', 40 * 1024);
    String? id;
    var chunks = 0;
    link.onDeliver = (from, message) {
      if (message is Chunk && ++chunks == 5) {
        link.onDeliver = null;
        if (id case final transferId?) {
          link.laptop.feature.cancel(transferId);
        }
      }
    };

    final sent = await send([source]);
    id = sent.id;
    await until(() => onPhone(sent.id)?.status == .cancelled);

    expect(onLaptop(sent.id)?.status, TransferStatus.cancelled);
    expect(onPhone(sent.id)?.failure, TransferFailure.cancelledByPeer);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(partFiles(phoneInbox), isEmpty);
    expect(File(p.join(phoneInbox.path, 'big.iso')).existsSync(), isFalse);
    final sentChunks = link.laptop.session?.sent.whereType<Chunk>().length;
    expect(sentChunks, lessThan(10));
  });

  test('the receiver can cancel, and the sender says so', () async {
    await startLink();
    final source = await randomFile(sources, 'clip.mov', 40 * 1024);
    String? id;
    var chunks = 0;
    link.onDeliver = (from, message) {
      if (message is Chunk && ++chunks == 5) {
        link.onDeliver = null;
        if (id case final transferId?) {
          link.phone.feature.cancel(transferId);
        }
      }
    };

    final sent = await send([source]);
    id = sent.id;
    await until(() => onLaptop(sent.id)?.status == .cancelled);

    expect(onLaptop(sent.id)?.failure, TransferFailure.cancelledByPeer);
    expect(onPhone(sent.id)?.status, TransferStatus.cancelled);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(partFiles(phoneInbox), isEmpty);
  });

  test('a corrupted file fails the checksum, and Retry fixes it', () async {
    await startLink();
    final source = await randomFile(sources, 'archive.zip', 5000);
    link.onDeliver = (from, message) {
      if (message is Chunk && message.offset.toInt() == 2048) {
        link.onDeliver = null;
        final corrupted = [...message.data];
        corrupted[0] ^= 0xff;
        message.data = corrupted;
      }
    };

    final sent = await send([source]);
    await until(() => onPhone(sent.id)?.status == .failed);
    await until(() => onLaptop(sent.id)?.status == .failed);

    expect(onPhone(sent.id)?.failure, TransferFailure.checksum);
    expect(onLaptop(sent.id)?.failure, TransferFailure.checksum);
    expect(File(p.join(phoneInbox.path, 'archive.zip')).existsSync(), isFalse);
    final failed = onPhone(sent.id);
    expect(failed, isNotNull);
    if (failed case final transfer?) {
      expect(link.phone.feature.canRetry(transfer), isTrue);
    }

    await link.phone.feature.retry(sent.id);
    await until(() => onPhone(sent.id)?.status == .done);
    await until(() => onLaptop(sent.id)?.status == .done);

    expect(
      await File(p.join(phoneInbox.path, 'archive.zip')).readAsBytes(),
      await source.readAsBytes(),
    );
  });

  test('text arrives as a finished transfer', () async {
    await startLink();

    final sent = link.laptop.feature.sendText(link.phone.id, 'Hello there');
    await until(() => onLaptop(sent.id)?.status == .done);

    final received = onPhone(sent.id);
    expect(received?.status, TransferStatus.done);
    expect(received?.text, 'Hello there');
    expect(received?.isText, isTrue);
    expect(received?.deviceName, 'Laptop');
  });

  test('without auto accept, the offer waits and can be declined', () async {
    await startLink(phoneSettings: {DropSettings.autoAccept: false});
    final source = await randomFile(sources, 'secret.txt', 100);

    final sent = await send([source]);
    await until(() => onPhone(sent.id)?.needsAnswer ?? false);
    expect(onLaptop(sent.id)?.status, TransferStatus.waiting);

    link.phone.feature.answer(sent.id, accept: false);
    await until(() => onLaptop(sent.id)?.status == .failed);

    expect(onLaptop(sent.id)?.failure, TransferFailure.declined);
    expect(onPhone(sent.id)?.status, TransferStatus.cancelled);
    expect(File(p.join(phoneInbox.path, 'secret.txt')).existsSync(), isFalse);
  });

  test('without auto accept, accepting receives the file', () async {
    await startLink(phoneSettings: {DropSettings.autoAccept: false});
    final source = await randomFile(sources, 'ok.txt', 1500);

    final sent = await send([source]);
    await until(() => onPhone(sent.id)?.needsAnswer ?? false);
    link.phone.feature.answer(sent.id, accept: true);
    await until(() => onPhone(sent.id)?.status == .done);

    expect(onPhone(sent.id)?.needsAnswer, isFalse);
    expect(
      await File(p.join(phoneInbox.path, 'ok.txt')).readAsBytes(),
      await source.readAsBytes(),
    );
  });

  test('folders and missing files are not sent', () async {
    await startLink();

    final transfer = await link.laptop.feature.sendFiles(link.phone.id, [
      sources.path,
      p.join(sources.path, 'missing.txt'),
    ]);

    expect(transfer, isNull);
  });
}
