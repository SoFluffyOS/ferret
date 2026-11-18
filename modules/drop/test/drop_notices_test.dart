import 'dart:async';
import 'dart:io';

import 'package:drop/drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/files.dart';
import 'support/linked_devices.dart';
import 'support/transfers.dart';

void main() {
  late LinkedDevices link;
  late _FakeNotifier notifier;
  late DropNotices notices;
  final opened = <String>[];
  final copied = <String>[];

  setUp(() async {
    final inbox = await Directory.systemTemp.createTemp('ferret_notices');
    addTearDown(() => inbox.delete(recursive: true));
    link = await LinkedDevices.start(
      laptopStore: folderStore(inbox),
      phoneStore: folderStore(inbox),
    );
    notifier = _FakeNotifier();
    opened.clear();
    copied.clear();
    notices = DropNotices(
      feature: link.laptop.feature,
      notifier: notifier,
      l10n: lookupDropLocalizations(const Locale('en')),
      onOpen: (transfer) async => opened.add(transfer.id),
      onReveal: (transfer) async {},
      onCopy: (text) async => copied.add(text),
    )..start();
    addTearDown(notices.dispose);
  });

  void put(Transfer transfer) => link.laptop.feature.registry.put(transfer);

  test('progress is silent and rate limited, the result is not', () async {
    put(sampleTransfer(bytesDone: 1));
    put(sampleTransfer(bytesDone: 2));
    put(sampleTransfer(bytesDone: 3));
    put(sampleTransfer(status: .done, bytesDone: 4 * 1024 * 1024));
    await pumpEventQueue();

    expect(notifier.shown, hasLength(2));
    expect(notifier.shown.first.silent, isTrue);
    expect(notifier.shown.first.progress, isNotNull);
    expect(notifier.shown.first.channel, NoticeChannel.transfers);
    final done = notifier.shown.last;
    expect(done.title, 'Received from Pixel');
    expect(done.category, DropNotices.filesCategory);
    expect(done.silent, isFalse);
  });

  test('received text offers Copy, and tapping Copy copies it', () async {
    put(sampleTransfer(status: .done, files: const [], text: 'Door code 4321'));
    await pumpEventQueue();

    final notice = notifier.shown.single;
    expect(notice.category, DropNotices.textCategory);
    expect(notice.body, 'Door code 4321');

    notifier.respond(
      NoticeResponse(noticeId: notice.id, actionId: DropNotices.copyAction),
    );
    await pumpEventQueue();
    expect(copied, ['Door code 4321']);
  });

  test('tapping a received file opens it', () async {
    put(sampleTransfer(status: .done));
    await pumpEventQueue();

    notifier.respond(NoticeResponse(noticeId: notifier.shown.single.id));
    await pumpEventQueue();
    expect(opened, ['t1']);
  });

  test('a cancelled transfer removes its notice', () async {
    put(sampleTransfer());
    put(sampleTransfer(status: .cancelled));
    await pumpEventQueue();

    expect(notifier.cancelled, [DropNotices.noticeId('t1')]);
  });
}

class _FakeNotifier implements LocalNotifier {
  final List<LocalNotice> shown = [];
  final List<String> cancelled = [];
  final StreamController<NoticeResponse> _responses = .broadcast();

  void respond(NoticeResponse response) => _responses.add(response);

  @override
  Future<void> show(LocalNotice notice) async => shown.add(notice);

  @override
  Future<void> cancel(String id) async => cancelled.add(id);

  @override
  Stream<NoticeResponse> get responses => _responses.stream;
}
