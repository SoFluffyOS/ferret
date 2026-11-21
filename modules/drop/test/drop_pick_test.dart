import 'dart:io';

import 'package:drop/drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/files.dart';
import 'support/linked_devices.dart';

void main() {
  late Directory root;
  late Directory picked;
  late Directory phoneInbox;
  late LinkedDevices link;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ferret_drop_pick');
    picked = await Directory(p.join(root.path, 'picked')).create();
    phoneInbox = Directory(p.join(root.path, 'phone'));
    link = await LinkedDevices.start(
      laptopStore: folderStore(Directory(p.join(root.path, 'laptop'))),
      phoneStore: folderStore(phoneInbox),
    );
  });

  tearDown(() => root.delete(recursive: true));

  Future<Transfer> pickAndSend(DropViewModel viewModel) async {
    final transfer = await viewModel.pickAndSend(link.phone.id);
    if (transfer == null) {
      throw StateError('Nothing sent');
    }

    await until(
      () => link.laptop.feature.registry[transfer.id]?.status == .done,
    );
    return transfer;
  }

  test("copies Android's picker made go once they are sent", () async {
    final copy = await randomFile(picked, 'photo.jpg', 5000);
    final viewModel = DropViewModel(
      feature: link.laptop.feature,
      pickFiles: () async => [copy.path],
      picksCopies: true,
      describeFolder: () async => '/storage/emulated/0/Download/Ferret',
    );
    addTearDown(viewModel.dispose);

    await pickAndSend(viewModel);

    expect(File(p.join(phoneInbox.path, 'photo.jpg')).existsSync(), isTrue);
    expect(copy.existsSync(), isFalse);
  });

  test("a computer's picked files stay where they are", () async {
    final original = await randomFile(picked, 'report.pdf', 5000);
    final viewModel = DropViewModel(
      feature: link.laptop.feature,
      pickFiles: () async => [original.path],
      describeFolder: () async => '/Users/me/Downloads/Ferret',
    );
    addTearDown(viewModel.dispose);

    expect(viewModel.picksCopies, isFalse);
    await pickAndSend(viewModel);

    expect(original.existsSync(), isTrue);
  });

  test("Android's own picker counts as making copies", () {
    debugDefaultTargetPlatformOverride = .android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final viewModel = DropViewModel(
      feature: link.laptop.feature,
      describeFolder: () async => '/storage/emulated/0/Download/Ferret',
    );
    addTearDown(viewModel.dispose);

    expect(viewModel.picksCopies, isTrue);
  });
}
