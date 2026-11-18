import 'dart:io';

import 'package:drop/drop.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/files.dart';
import 'support/linked_devices.dart';
import 'support/transfers.dart';

void main() {
  late LinkedDevices link;
  late DropViewModel viewModel;
  final l10n = lookupDropLocalizations(const Locale('en'));

  setUp(() async {
    final inbox = Directory.systemTemp.createTempSync('ferret_drop_activity');
    addTearDown(() => inbox.deleteSync(recursive: true));
    link = await LinkedDevices.start(
      laptopStore: folderStore(inbox),
      phoneStore: folderStore(inbox),
    );
    viewModel = DropViewModel(
      feature: link.laptop.feature,
      describeFolder: () async => '/Users/me/Downloads/Ferret',
    );
    addTearDown(viewModel.dispose);
  });

  Future<List<ActivityItemView>> rowsAfter(Transfer transfer) async {
    link.laptop.feature.registry.put(transfer);
    await Future<void>.delayed(Duration.zero);
    return [
      for (final item in dropActivity(l10n, viewModel))
        (
          title: item.title,
          detail: item.detail,
          pinned: item.pinned,
          progress: item.progress,
          actions: [for (final action in item.actions) action.label],
        ),
    ];
  }

  test('a running transfer is pinned with its progress and Cancel', () async {
    final rows = await rowsAfter(sampleTransfer(bytesDone: 1024 * 1024));

    expect(rows.single.title, 'photo.jpg from Pixel');
    expect(rows.single.pinned, isTrue);
    expect(rows.single.progress, 0.25);
    expect(rows.single.actions, ['Cancel']);
  });

  test('a received file says where it was saved and offers Open', () async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final rows = await rowsAfter(
      sampleTransfer(status: .done, bytesDone: 4 * 1024 * 1024),
    );

    expect(rows.single.title, 'photo.jpg from Pixel');
    expect(rows.single.detail, startsWith('Saved'));
    expect(rows.single.pinned, isFalse);
    expect(rows.single.actions, ['Open']);
  });

  test('a received text offers Copy', () async {
    final rows = await rowsAfter(
      sampleTransfer(status: .done, files: const [], text: 'See you at 6'),
    );

    expect(rows.single.title, 'Text from Pixel');
    expect(rows.single.detail, 'See you at 6');
    expect(rows.single.actions, ['Copy']);
  });

  test('a send that failed says why in plain words', () async {
    final rows = await rowsAfter(
      sampleTransfer(
        direction: .outgoing,
        status: .failed,
        failure: .disconnected,
      ),
    );

    expect(rows.single.title, 'photo.jpg to Pixel');
    expect(rows.single.detail, contains('It went offline'));
  });

  test('an offer waiting for an answer stays on the card', () async {
    final rows = await rowsAfter(
      sampleTransfer(status: .waiting, needsAnswer: true),
    );

    expect(rows, isEmpty);
    expect(viewModel.needingAnswer.single.id, 't1');
  });
}

typedef ActivityItemView = ({
  String title,
  String? detail,
  bool pinned,
  double? progress,
  List<String> actions,
});
