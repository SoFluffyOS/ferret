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
    root = await Directory.systemTemp.createTemp('ferret_drop_folder');
    sources = await Directory(p.join(root.path, 'sources')).create();
    laptopInbox = Directory(p.join(root.path, 'laptop'));
    phoneInbox = Directory(p.join(root.path, 'phone'));
    link = await LinkedDevices.start(
      laptopStore: folderStore(laptopInbox),
      phoneStore: folderStore(phoneInbox),
    );
  });

  tearDown(() => root.delete(recursive: true));

  Transfer? onPhone(String id) => link.phone.feature.registry[id];

  Transfer? onLaptop(String id) => link.laptop.feature.registry[id];

  /// Photos/2024/b.jpg, Photos/2024/june/c.jpg and Photos/a.jpg, in the
  /// order they are sent.
  Future<Directory> photos() async {
    final folder = await Directory(
      p.join(sources.path, 'Photos', '2024', 'june'),
    ).create(recursive: true);
    final top = Directory(p.join(sources.path, 'Photos'));
    await randomFile(top, 'a.jpg', 3000);
    await randomFile(Directory(p.dirname(folder.path)), 'b.jpg', 5000);
    await randomFile(folder, 'c.jpg', 2048);
    await File(p.join(top.path, '.DS_Store')).writeAsString('x');
    return top;
  }

  Future<Transfer> send(List<String> paths) async {
    final transfer = await link.laptop.feature.sendFiles(link.phone.id, paths);
    if (transfer == null) {
      throw StateError('Nothing to send');
    }

    return transfer;
  }

  test('a folder arrives as its whole tree, times kept', () async {
    final folder = await photos();
    final when = DateTime(2024, 6, 1, 12);
    await File(p.join(folder.path, 'a.jpg')).setLastModified(when);

    final sent = await send([folder.path]);
    await until(() => onPhone(sent.id)?.status == .done);

    final received = onPhone(sent.id);
    expect(received?.folderName, 'Photos');
    expect(received?.files.length, 3);
    final saved = p.join(phoneInbox.path, 'Photos');
    expect(received?.folderLocation, saved);
    for (final relative in ['a.jpg', '2024/b.jpg', '2024/june/c.jpg']) {
      final source = File(p.join(folder.path, relative));
      final copy = File(p.join(saved, relative));
      expect(await copy.readAsBytes(), await source.readAsBytes());
    }
    expect(
      File(p.join(saved, 'a.jpg')).lastModifiedSync(),
      when,
    );
    expect(File(p.join(saved, '.DS_Store')).existsSync(), isFalse);
  });

  test('never merges into a folder that is there: Photos (2)', () async {
    final folder = await photos();
    final existing = await Directory(
      p.join(phoneInbox.path, 'Photos'),
    ).create(recursive: true);
    await File(p.join(existing.path, 'a.jpg')).writeAsString('mine');

    final sent = await send([folder.path]);
    await until(() => onPhone(sent.id)?.status == .done);

    expect(onPhone(sent.id)?.folderName, 'Photos (2)');
    expect(
      await File(p.join(existing.path, 'a.jpg')).readAsString(),
      'mine',
    );
    expect(
      File(p.join(phoneInbox.path, 'Photos (2)', '2024', 'june', 'c.jpg'))
          .existsSync(),
      isTrue,
    );
  });

  test('links inside a folder are left out and counted', () async {
    final folder = await photos();
    await Link(p.join(folder.path, 'elsewhere')).create('/etc');
    await Link(p.join(folder.path, 'passwd')).create('/etc/passwd');

    final sent = await send([folder.path]);
    await until(() => onPhone(sent.id)?.status == .done);

    expect(onLaptop(sent.id)?.skipped, 2);
    expect(onPhone(sent.id)?.files.length, 3);
    expect(
      Directory(p.join(phoneInbox.path, 'Photos', 'elsewhere')).existsSync(),
      isFalse,
    );
  });

  test('resumes mid-folder from the file and offset it stopped at', () async {
    final folder = await photos();
    var chunks = 0;
    link.onDeliver = (from, message) {
      if (message is Chunk && ++chunks == 7) {
        link
          ..onDeliver = null
          ..drop();
      }
    };

    final sent = await send([folder.path]);
    await until(() => onPhone(sent.id)?.isPaused ?? false);
    await until(() => onLaptop(sent.id)?.isPaused ?? false);
    expect(onPhone(sent.id)?.filesDone, 1);

    link.connect();
    await until(() => onPhone(sent.id)?.status == .done);
    await until(() => onLaptop(sent.id)?.status == .done);

    final resume = link.phone.session?.sent.whereType<ResumeRequest>().single;
    expect(resume?.fileIndex, 1);
    expect(resume?.offset.toInt(), 1024);
    final saved = p.join(phoneInbox.path, 'Photos');
    expect(
      await File(p.join(saved, '2024', 'june', 'c.jpg')).readAsBytes(),
      await File(p.join(folder.path, '2024', 'june', 'c.jpg')).readAsBytes(),
    );
    expect(
      Directory(p.join(phoneInbox.path, 'Photos (2)')).existsSync(),
      isFalse,
    );
  });

  test(
    'an older Ferret gets nothing, and the files can go on their own',
    () async {
      final folder = await photos();
      link.phone.announcedFlags = const ['send', 'receive', 'resume'];

      final sent = await send([folder.path]);
      await until(() => onLaptop(sent.id)?.status == .failed);

      expect(onLaptop(sent.id)?.failure, TransferFailure.foldersUnsupported);
      expect(link.laptop.session?.sent.whereType<TransferOffer>(), isEmpty);

      final loose = await link.laptop.feature.sendLoose(sent.id);
      if (loose == null) {
        fail('Nothing sent on its own');
      }

      await until(() => onPhone(loose.id)?.status == .done);
      expect(onLaptop(sent.id), isNull);
      expect(onPhone(loose.id)?.isFolder, isFalse);
      expect(File(p.join(phoneInbox.path, 'c.jpg')).existsSync(), isTrue);
    },
  );

  test('a hostile folder in an offer is refused whole', () async {
    final session = link.phone.session;
    if (session == null) {
      fail('Not linked');
    }

    for (final hostile in ['../outside', '/etc', r'C:\Windows', 'a/../../b']) {
      final offer = TransferOffer(
        transferId: 'hostile${hostile.hashCode.abs()}',
        files: [FileInfo(name: 'x.txt', size: Int64(1), folder: hostile)],
      );
      final answer = await link.phone.feature.onEnvelope(
        session,
        Envelope(
          feature: DropFeature.featureId,
          type: offer.payloadType,
          payload: offer.toPayload(),
          expectsReply: true,
        ),
      );

      expect((answer as TransferAnswer?)?.accepted, isFalse, reason: hostile);
      expect(
        answer?.reason,
        DeclineReason.DECLINE_REASON_INVALID,
        reason: hostile,
      );
    }
  });
}
