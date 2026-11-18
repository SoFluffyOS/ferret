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
          needsYou: item.needsYou,
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
    expect(rows.single.detail, '1 MB of 4 MB');
    expect(rows.single.actions, ['Cancel']);
  });

  test('a running send says only how far it is, and the time left', () async {
    final rows = await rowsAfter(
      sampleTransfer(
        direction: .outgoing,
        bytesDone: 1024 * 1024,
        bytesPerSecond: 1024 * 1024,
      ),
    );

    expect(rows.single.title, 'photo.jpg to Pixel');
    expect(rows.single.detail, '1 MB of 4 MB · 3 s left');
  });

  test('a received file says where it was saved and offers Open', () async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final rows = await rowsAfter(
      sampleTransfer(status: .done, bytesDone: 4 * 1024 * 1024),
    );

    expect(rows.single.title, 'photo.jpg from Pixel');
    expect(rows.single.detail, startsWith('Saved'));
    expect(rows.single.pinned, isFalse);
    expect(rows.single.actions, ['Open', TransferTexts(l10n).revealLabel()]);
  });

  test('several received files offer only Show in folder', () async {
    final rows = await rowsAfter(
      sampleTransfer(
        status: .done,
        files: const [
          TransferFile(name: 'a.jpg', size: 1, location: '/tmp/a.jpg'),
          TransferFile(name: 'b.jpg', size: 1, location: '/tmp/b.jpg'),
        ],
      ),
    );

    expect(rows.single.title, '2 files from Pixel');
    expect(rows.single.actions, [TransferTexts(l10n).revealLabel()]);
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

  test('an offer waits under Needs you with its size, Decline and '
      'Accept', () async {
    final rows = await rowsAfter(
      sampleTransfer(status: .waiting, needsAnswer: true),
    );

    expect(rows.single.title, 'Pixel wants to send');
    expect(rows.single.detail, 'photo.jpg · 4 MB');
    expect(rows.single.needsYou, isTrue);
    expect(rows.single.actions, ['Decline', 'Accept']);
    expect(viewModel.needingPin, isEmpty);
  });

  test("Accept is the offer's one filled button", () async {
    link.laptop.feature.registry.put(
      sampleTransfer(status: .waiting, needsAnswer: true),
    );
    await Future<void>.delayed(Duration.zero);
    final line = dropActivity(l10n, viewModel).single;

    expect(line.actions.last.primary, isTrue);
    expect(line.actions.first.primary, isFalse);
  });

  test('tapping an offer asks for its details', () async {
    final asked = <String>[];
    link.laptop.feature.registry.put(
      sampleTransfer(status: .waiting, needsAnswer: true),
    );
    await Future<void>.delayed(Duration.zero);

    dropActivity(
      l10n,
      viewModel,
      onOfferDetails: (transfer) => asked.add(transfer.id),
    ).single.onTap?.call();

    expect(asked, ['t1']);
  });

  test('the Mac says Show in Finder, other systems Show in folder', () {
    final texts = TransferTexts(l10n);

    expect(texts.revealLabel(platform: .macOS), 'Show in Finder');
    expect(texts.revealLabel(platform: .windows), 'Show in folder');
    expect(texts.revealLabel(platform: .android), 'Show in folder');
  });
}

typedef ActivityItemView = ({
  String title,
  String? detail,
  bool pinned,
  bool needsYou,
  double? progress,
  List<String> actions,
});
