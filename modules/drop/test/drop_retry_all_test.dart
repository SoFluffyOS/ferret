import 'dart:io';

import 'package:drop/drop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/files.dart';
import 'support/linked_devices.dart';

void main() {
  late Directory root;
  late Directory sources;
  late Directory phoneInbox;
  late LinkedDevices link;
  late DropViewModel viewModel;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_drop_retry_all');
    sources = await Directory(p.join(root.path, 'sources')).create();
    phoneInbox = Directory(p.join(root.path, 'phone'));
    link = await LinkedDevices.start(
      laptopStore: folderStore(Directory(p.join(root.path, 'laptop'))),
      phoneStore: folderStore(phoneInbox),
    );
    viewModel = DropViewModel(
      feature: link.laptop.feature,
      describeFolder: () async => '/Users/me/Downloads/Ferret',
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await root.delete(recursive: true);
  });

  Future<Transfer> send(String name) async {
    final file = await randomFile(sources, name, 3000);
    final transfer = await link.laptop.feature.sendFiles(
      link.phone.id,
      [file.path],
    );

    return transfer ?? (throw StateError('Nothing to send'));
  }

  test('one link tries every stopped transfer with a device again', () async {
    link.drop();
    final first = await send('one.pdf');
    final second = await send('two.pdf');
    await until(
      () => viewModel.retryableWith(link.phone.id).length == 2,
    );
    expect(viewModel.retryableWith('someone-else'), isEmpty);

    link.connect();
    await viewModel.retryAllWith(link.phone.id);
    await until(
      () =>
          link.laptop.feature.registry[first.id]?.status == .done &&
          link.laptop.feature.registry[second.id]?.status == .done,
    );

    expect(viewModel.retryableWith(link.phone.id), isEmpty);
    expect(File(p.join(phoneInbox.path, 'one.pdf')).existsSync(), isTrue);
    expect(File(p.join(phoneInbox.path, 'two.pdf')).existsSync(), isTrue);
  });
}
