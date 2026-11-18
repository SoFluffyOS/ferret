import 'dart:io';

import 'package:drop/drop.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/files.dart';
import 'support/linked_devices.dart';
import 'support/transfers.dart';

void main() {
  late LinkedDevices link;
  late DropViewModel viewModel;

  setUp(() async {
    final inbox = Directory.systemTemp.createTempSync('ferret_drop_busy');
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

  Future<void> put(Transfer transfer) async {
    link.laptop.feature.registry.put(transfer);
    await pumpEventQueue();
  }

  test('nothing running, nothing waiting, nothing finished at rest', () {
    final busy = viewModel.busy;

    expect(busy.progress, isNull);
    expect(busy.waitingCount, 0);
    expect(busy.finishedCount, 0);
  });

  test(
    'a running transfer reports how far it got and who it is with',
    () async {
      await put(
        sampleTransfer(direction: .outgoing, bytesDone: 1024 * 1024),
      );

      final busy = viewModel.busy;

      expect(busy.progress, 0.25);
      expect(busy.peerName, 'Pixel');
      expect(busy.isSending, isTrue);
      expect(busy.waitingCount, 0);
    },
  );

  test('two running transfers share one progress', () async {
    await put(sampleTransfer(bytesDone: 4 * 1024 * 1024));
    await put(sampleTransfer(id: 't2'));

    expect(viewModel.busy.progress, 0.5);
    expect(viewModel.busy.isSending, isFalse);
  });

  test('an offer waiting for an answer needs the person, not a ring', () async {
    await put(sampleTransfer(status: .waiting, needsAnswer: true));

    final busy = viewModel.busy;

    expect(busy.progress, isNull);
    expect(busy.waitingCount, 1);
    expect(busy.waitingName, 'Pixel');
  });

  test('a transfer that goes through counts as finished, once', () async {
    await put(sampleTransfer());
    await put(sampleTransfer(status: .done, bytesDone: 4 * 1024 * 1024));
    await put(sampleTransfer(status: .done, bytesDone: 4 * 1024 * 1024));

    expect(viewModel.busy.progress, isNull);
    expect(viewModel.busy.finishedCount, 1);
  });

  test('a transfer that fails or is cancelled never counts', () async {
    await put(sampleTransfer());
    await put(sampleTransfer(status: .failed, failure: .disconnected));
    await put(sampleTransfer(id: 't2'));
    await put(sampleTransfer(id: 't2', status: .cancelled));

    expect(viewModel.busy.progress, isNull);
    expect(viewModel.busy.finishedCount, 0);
  });
}
