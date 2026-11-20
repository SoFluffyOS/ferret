import 'dart:io';

import 'package:drop/drop.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/drop.dart';
import 'package:protocol/protocol.dart' hide Platform;

import 'support/files.dart';
import 'support/linked_devices.dart';

const _megabyte = 1024 * 1024;

/// A plain folder store whose free space the test sets, standing in for the
/// platform's reading. [copies] makes it save like MediaStore does.
class _SpaceStore extends FolderReceiveStore {
  _SpaceStore(Directory folder, {this.copies = false})
    : super(() async => folder.path);

  int? free;
  int reads = 0;
  final bool copies;

  @override
  Future<int?> freeBytes() async {
    reads++;
    return free;
  }

  @override
  Future<bool> copiesOnSave() async => copies;
}

void main() {
  final l10n = lookupDropLocalizations(const Locale('en'));
  final texts = TransferTexts(l10n);
  late Directory root;
  late Directory sources;
  late Directory phoneInbox;
  late _SpaceStore phoneStore;
  late LinkedDevices link;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_drop_space');
    sources = await Directory(p.join(root.path, 'sources')).create();
    phoneInbox = Directory(p.join(root.path, 'phone'));
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<void> startLink({
    bool copies = false,
    int? free,
    bool autoAccept = true,
  }) async {
    phoneStore = _SpaceStore(phoneInbox, copies: copies)..free = free;
    link = await LinkedDevices.start(
      laptopStore: folderStore(Directory(p.join(root.path, 'laptop'))),
      phoneStore: (_) => phoneStore,
      phoneSettings: {DropSettings.autoAccept: autoAccept},
    );
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

  test('files that do not fit are turned down before anything is written, '
      'and both sides say how short it is', () async {
    await startLink(free: 12 * _megabyte);
    final source = await randomFile(sources, 'clip.mov', 3000);

    final sent = await send([source]);
    await until(() => onLaptop(sent.id)?.status == .failed);

    final there = onLaptop(sent.id);
    expect(there?.failure, TransferFailure.outOfSpace);
    expect(there?.freeBytes, 12 * _megabyte);
    expect(
      texts.failure(there!),
      'Phone is out of space: needs 2.9 KB, '
      '12 MB free',
    );

    final here = onPhone(sent.id);
    expect(here?.status, TransferStatus.failed);
    expect(here?.failure, TransferFailure.outOfSpace);
    expect(
      texts.failure(here!),
      'Not enough space for clip.mov: needs '
      '2.9 KB, 12 MB free',
    );
    expect(here.canRetry, isFalse);
    expect(there.canRetry, isTrue);

    final chunks = link.laptop.session?.sent.whereType<Chunk>() ?? [];
    expect(chunks, isEmpty);
    expect(phoneInbox.existsSync(), isFalse);
  });

  test(
    'the answer carries the free bytes on the existing storage reason',
    () async {
      await startLink(free: 5 * _megabyte);
      final session = link.phone.session;
      if (session == null) {
        throw StateError('Not linked');
      }

      final offer = TransferOffer(
        transferId: 'space-check',
        files: [FileInfo(name: 'a.bin', size: Int64(10))],
      );
      final reply = await link.phone.feature.onEnvelope(
        session,
        Envelope(
          feature: DropFeature.featureId,
          type: offer.payloadType,
          payload: offer.toPayload(),
          expectsReply: true,
        ),
      );

      expect(reply, isA<TransferAnswer>());
      final answer = reply! as TransferAnswer;
      expect(answer.accepted, isFalse);
      expect(answer.reason, DeclineReason.DECLINE_REASON_STORAGE);
      expect(answer.offset.toInt(), 5 * _megabyte);
    },
  );

  test('a folder says its name in the line here', () async {
    await startLink(free: _megabyte);
    final folder = await Directory(p.join(sources.path, 'Photos')).create();
    await randomFile(folder, 'one.jpg', 2048);
    await randomFile(folder, 'two.jpg', 2048);

    final sent = await send([File(folder.path)]);
    await until(() => onPhone(sent.id)?.status == .failed);

    expect(
      texts.failure(onPhone(sent.id)!),
      'Not enough space for Photos: needs 4 KB, 1 MB free',
    );
  });

  test('with room to spare, the files arrive', () async {
    await startLink(free: 10 * 1024 * _megabyte);
    final source = await randomFile(sources, 'clip.mov', 3000);

    final sent = await send([source]);
    await until(() => onPhone(sent.id)?.status == .done);

    expect(phoneStore.reads, 1);
    expect(File(p.join(phoneInbox.path, 'clip.mov')).existsSync(), isTrue);
  });

  test('when the free space cannot be told, the files still go', () async {
    await startLink();
    final source = await randomFile(sources, 'clip.mov', 3000);

    final sent = await send([source]);
    await until(() => onPhone(sent.id)?.status == .done);

    expect(onLaptop(sent.id)?.failure, isNull);
  });

  test('a small margin stays free', () async {
    await startLink(free: DropReceiver.spaceMargin + 2999);
    final source = await randomFile(sources, 'clip.mov', 3000);

    final sent = await send([source]);
    await until(() => onLaptop(sent.id)?.status == .failed);

    expect(onLaptop(sent.id)?.failure, TransferFailure.outOfSpace);
  });

  test(
    'where saving copies, the biggest files need their room twice',
    () async {
      const big = 4000;
      const small = 100;
      const total = big + small;
      await startLink(copies: true, free: DropReceiver.spaceMargin + total);
      final first = await randomFile(sources, 'big.bin', big);
      final second = await randomFile(sources, 'small.bin', small);

      final short = await send([first, second]);
      await until(() => onLaptop(short.id)?.status == .failed);
      expect(onLaptop(short.id)?.failure, TransferFailure.outOfSpace);

      phoneStore.free = DropReceiver.spaceMargin + total + big + small;
      final fits = await send([first, second]);
      await until(() => onPhone(fits.id)?.status == .done);
    },
  );

  test(
    'without auto accept, nobody is asked about files that cannot fit',
    () async {
      await startLink(free: _megabyte, autoAccept: false);
      final asked = <String>[];
      final subscription = link.phone.feature.updates.listen((transfer) {
        if (transfer.needsAnswer) {
          asked.add(transfer.id);
        }
      });
      addTearDown(subscription.cancel);
      final source = await randomFile(sources, 'clip.mov', 3000);

      final sent = await send([source]);
      await until(() => onLaptop(sent.id)?.status == .failed);

      expect(asked, isEmpty);
      expect(onPhone(sent.id)?.failure, TransferFailure.outOfSpace);
    },
  );

  test('after making room, Retry sends the files', () async {
    await startLink(free: _megabyte);
    final source = await randomFile(sources, 'clip.mov', 3000);
    final sent = await send([source]);
    await until(() => onLaptop(sent.id)?.status == .failed);

    phoneStore.free = 10 * 1024 * _megabyte;
    await link.laptop.feature.retry(sent.id);
    await until(() => onPhone(sent.id)?.status == .done);
    await until(() => onLaptop(sent.id)?.status == .done);

    expect(onLaptop(sent.id)?.freeBytes, isNull);
    expect(onPhone(sent.id)?.failure, isNull);
  });

  test('the line here offers a place to make room', () async {
    await startLink(free: _megabyte);
    final viewModel = DropViewModel(
      feature: link.phone.feature,
      describeFolder: () async => '/Users/me/Downloads/Ferret',
    );
    addTearDown(viewModel.dispose);
    final source = await randomFile(sources, 'clip.mov', 3000);
    final sent = await send([source]);
    await until(() => onPhone(sent.id)?.status == .failed);

    for (final (platform, label) in [
      (TargetPlatform.android, 'Open Settings'),
      (TargetPlatform.macOS, 'Show in Finder'),
      (TargetPlatform.windows, 'Show in folder'),
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      final rows = dropActivity(l10n, viewModel);
      expect(
        [for (final action in rows.single.actions) action.label],
        [label],
        reason: '$platform',
      );
    }

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(dropActivity(l10n, viewModel).single.actions, isEmpty);
    debugDefaultTargetPlatformOverride = null;
  });
}
