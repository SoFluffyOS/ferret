import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drop/drop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interop_quickshare/interop_quickshare.dart';
import 'package:path/path.dart' as p;

import 'support/files.dart';
import 'support/localsend_devices.dart';
import 'support/quickshare_phone.dart';

Uint8List _bytes(int size, int seed) => Uint8List.fromList([
  for (var index = 0; index < size; index++) (index * 31 + seed) % 256,
]);

void main() {
  late Directory inbox;
  late SoloDevice laptop;
  late QuickSharePhone phone;

  setUp(() async {
    inbox = await Directory.systemTemp.createTemp('ferret_quickshare_in');
    laptop = await SoloDevice.start('Laptop', inbox);
    phone = QuickSharePhone(laptop);
  });

  tearDown(() async {
    await laptop.feature.stop();
    await inbox.delete(recursive: true);
  });

  Transfer? onLaptop() => laptop.transfers.firstOrNull;

  Future<Transfer> offer() async {
    await until(() => onLaptop()?.needsAnswer ?? false);
    return laptop.transfers.first;
  }

  group('visibility', () {
    test('is off until someone turns it on', () {
      expect(laptop.quickShare.isEnabled, isTrue);
      expect(laptop.quickShare.receiveState.isOn, isFalse);
      expect(laptop.quickShare.port, isNull);
    });

    test('turns on for 10 minutes, with the time left', () async {
      await laptop.quickShare.receiveForAWhile();

      final state = laptop.quickShare.receiveState;
      expect(state.isOn, isTrue);
      expect(state.name, 'Laptop');
      expect(state.problem, isNull);
      final left = state.remaining(DateTime.now()) ?? Duration.zero;
      expect(left.inSeconds, inInclusiveRange(595, 600));

      await laptop.quickShare.stopReceiving();
      expect(laptop.quickShare.receiveState.isOn, isFalse);
      expect(laptop.quickShare.receiveState.remaining(DateTime.now()), isNull);
      expect(laptop.quickShare.port, isNull);
    });

    test('turns itself off when the window ends', () async {
      await laptop.feature.stop();
      laptop = await SoloDevice.start(
        'Laptop',
        inbox,
        quickShare: QuickShareOptions(
          bindAddress: InternetAddress.loopbackIPv4,
          advertise: false,
          receiveWindow: const Duration(milliseconds: 150),
        ),
      );
      final changes = <bool>[];
      final subscription = laptop.quickShare.changes.listen(
        (_) => changes.add(laptop.quickShare.receiveState.isOn),
      );
      addTearDown(subscription.cancel);

      await laptop.quickShare.receiveForAWhile();
      expect(laptop.quickShare.receiveState.isOn, isTrue);

      await until(() => changes.contains(true) && !changes.last);
      expect(laptop.quickShare.receiveState.isOn, isFalse);
      expect(laptop.quickShare.port, isNull);
    });

    test('says so when the port is taken', () async {
      final taken = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(taken.close);
      await laptop.feature.stop();
      laptop = await SoloDevice.start(
        'Laptop',
        inbox,
        quickShare: QuickShareOptions(
          port: taken.port,
          bindAddress: InternetAddress.loopbackIPv4,
          advertise: false,
        ),
      );

      await laptop.quickShare.receiveForAWhile();

      final state = laptop.quickShare.receiveState;
      expect(state.isOn, isFalse);
      expect(state.problem, QuickShareProblem.cannotListen);
      expect(state.remaining(DateTime.now()), isNull);
    });

    test('turned off in settings, it stops and stays off', () async {
      await laptop.quickShare.receiveForAWhile();

      await laptop.quickShare.setEnabled(false);

      expect(laptop.quickShare.isEnabled, isFalse);
      expect(laptop.quickShare.receiveState.isOn, isFalse);
      await laptop.quickShare.receiveForAWhile();
      expect(laptop.quickShare.receiveState.isOn, isFalse);
      expect(
        laptop.settings.get<bool>(DropSettings.quickShareEnabled),
        isFalse,
      );
    });
  });

  group('receiving', () {
    test(
      'an offer waits with the PIN the phone shows, then files land',
      () async {
        final photo = _bytes(120 * 1024, 1);
        final notes = _bytes(900, 2);
        await laptop.quickShare.receiveForAWhile();

        final sending = phone.send(
          files: [phoneFile('photo.jpg', photo), phoneFile('notes.txt', notes)],
        );
        final waiting = await offer();

        expect(waiting.deviceName, 'Pixel 8 (Quick Share)');
        expect(waiting.isQuickShare, isTrue);
        expect(waiting.isUnpaired, isTrue);
        expect(waiting.status, TransferStatus.waiting);
        expect(waiting.quickShare?.pin, matches(RegExp(r'^\d{4}$')));
        expect(waiting.quickShare?.pin, phone.pin);
        expect(waiting.quickShare?.address, '127.0.0.1');
        expect(waiting.files.map((file) => file.name), [
          'photo.jpg',
          'notes.txt',
        ]);
        expect(waiting.totalBytes, photo.length + notes.length);
        expect(inbox.listSync(), isEmpty);

        laptop.feature.answer(waiting.id, accept: true);

        expect(await sending, QuickShareSendResult.sent);
        await until(() => onLaptop()?.status == TransferStatus.done);
        final done = laptop.transfers.single;
        expect(done.needsAnswer, isFalse);
        expect(done.bytesDone, done.totalBytes);
        expect(
          await File(p.join(inbox.path, 'photo.jpg')).readAsBytes(),
          photo,
        );
        expect(
          await File(p.join(inbox.path, 'notes.txt')).readAsBytes(),
          notes,
        );
        expect(done.files.first.location, p.join(inbox.path, 'photo.jpg'));
        expect(partFiles(inbox), isEmpty);
        expect(laptop.feature.canRetry(done), isFalse);
      },
    );

    test('never overwrites, and never trusts a name as a path', () async {
      await File(p.join(inbox.path, 'photo.jpg')).writeAsString('mine');
      await laptop.quickShare.receiveForAWhile();

      final sending = phone.send(
        files: [
          phoneFile('photo.jpg', _bytes(10, 1)),
          phoneFile('../../escape.sh', _bytes(10, 2)),
        ],
      );
      final waiting = await offer();
      expect(waiting.files.last.name, 'escape.sh');
      laptop.feature.answer(waiting.id, accept: true);
      await sending;
      await until(() => onLaptop()?.status == TransferStatus.done);

      expect(
        await File(p.join(inbox.path, 'photo.jpg')).readAsString(),
        'mine',
      );
      expect(File(p.join(inbox.path, 'photo (1).jpg')).existsSync(), isTrue);
      expect(File(p.join(inbox.path, 'escape.sh')).existsSync(), isTrue);
      expect(laptop.transfers.single.files.first.name, 'photo (1).jpg');
      expect(
        File(p.join(inbox.parent.path, 'escape.sh')).existsSync(),
        isFalse,
      );
    });

    test('a shared folder arrives as a folder of its own', () async {
      await Directory(p.join(inbox.path, 'Camera')).create();
      await laptop.quickShare.receiveForAWhile();

      final sending = phone.send(
        files: [
          inFolder(phoneFile('a.jpg', _bytes(10, 1)), 'Camera'),
          inFolder(phoneFile('b.jpg', _bytes(20, 2)), 'Camera/2024'),
        ],
      );
      final waiting = await offer();
      expect(waiting.folderName, 'Camera');
      laptop.feature.answer(waiting.id, accept: true);
      await sending;
      await until(() => onLaptop()?.status == TransferStatus.done);

      expect(onLaptop()?.folderName, 'Camera (2)');
      expect(
        await File(
          p.join(inbox.path, 'Camera (2)', '2024', 'b.jpg'),
        ).readAsBytes(),
        _bytes(20, 2),
      );
    });

    test('a folder that climbs out is refused', () async {
      await laptop.quickShare.receiveForAWhile();

      await phone
          .send(
            files: [inFolder(phoneFile('a.sh', _bytes(10, 1)), '../../bin')],
          )
          .timeout(const Duration(seconds: 5), onTimeout: () => fail('hung'))
          .then((_) {}, onError: (Object _) {});

      expect(laptop.transfers, isEmpty);
      expect(
        File(p.join(inbox.parent.path, 'bin', 'a.sh')).existsSync(),
        isFalse,
      );
    });

    test('a text stays hidden until it is accepted', () async {
      await laptop.quickShare.receiveForAWhile();

      final sending = phone.send(text: 'https://example.com/tickets');
      final waiting = await offer();
      expect(waiting.isText, isTrue);
      expect(waiting.text, isNull);

      laptop.feature.answer(waiting.id, accept: true);
      expect(await sending, QuickShareSendResult.sent);
      await until(() => onLaptop()?.status == TransferStatus.done);

      expect(laptop.transfers.single.text, 'https://example.com/tickets');
      expect(inbox.listSync(), isEmpty);
    });

    test('a text sent along with files gets its own entry', () async {
      await laptop.quickShare.receiveForAWhile();

      final sending = phone.send(
        files: [phoneFile('a.bin', _bytes(100, 3))],
        text: 'for you',
      );
      laptop.feature.answer((await offer()).id, accept: true);
      await sending;
      await until(
        () =>
            laptop.transfers.length == 2 &&
            laptop.transfers.every((transfer) => transfer.status == .done),
      );

      final text = laptop.transfers.firstWhere((transfer) => transfer.isText);
      final files = laptop.transfers.firstWhere((transfer) => !transfer.isText);
      expect(text.text, 'for you');
      expect(text.deviceName, 'Pixel 8 (Quick Share)');
      expect(files.files.single.location, p.join(inbox.path, 'a.bin'));
    });
  });

  group('declining and cancelling', () {
    test('a declined offer sends nothing', () async {
      await laptop.quickShare.receiveForAWhile();
      final sending = phone.send(files: [phoneFile('a.bin', _bytes(100, 1))]);

      laptop.feature.answer((await offer()).id, accept: false);

      expect(await sending, QuickShareSendResult.declined);
      final declined = laptop.transfers.single;
      expect(declined.status, TransferStatus.cancelled);
      expect(declined.failure, TransferFailure.declined);
      expect(declined.needsAnswer, isFalse);
      expect(inbox.listSync(), isEmpty);
    });

    test('an offer nobody answers times out', () async {
      await laptop.feature.stop();
      laptop = await SoloDevice.start(
        'Laptop',
        inbox,
        quickShare: QuickShareOptions(
          bindAddress: InternetAddress.loopbackIPv4,
          advertise: false,
          answerTimeout: const Duration(milliseconds: 150),
          timeouts: loopbackQuickShare.timeouts,
        ),
      );
      phone = QuickSharePhone(laptop);
      await laptop.quickShare.receiveForAWhile();

      final result = await phone.send(
        files: [phoneFile('a.bin', _bytes(10, 1))],
      );

      expect(result, QuickShareSendResult.declined);
      expect(onLaptop()?.status, TransferStatus.failed);
      expect(onLaptop()?.failure, TransferFailure.timedOut);
      expect(onLaptop()?.needsAnswer, isFalse);
    });

    test('the phone taking its offer back clears the question', () async {
      await laptop.quickShare.receiveForAWhile();
      final sending = phone.send(files: [phoneFile('a.bin', _bytes(100, 1))]);
      final waiting = await offer();

      await phone.cancel();

      expect(await sending, QuickShareSendResult.cancelled);
      await until(() => onLaptop()?.status == TransferStatus.cancelled);
      expect(onLaptop()?.failure, TransferFailure.cancelledByPeer);
      expect(onLaptop()?.needsAnswer, isFalse);
      laptop.feature.answer(waiting.id, accept: true);
      expect(onLaptop()?.status, TransferStatus.cancelled);
    });

    test('cancelling here mid-file stops the phone and cleans up', () async {
      final gate = Completer<void>();
      await laptop.quickShare.receiveForAWhile();
      final sending = phone.send(
        files: [
          gatedPhoneFile(
            'big.bin',
            _bytes(64 * 1024, 1),
            _bytes(10, 2),
            gate.future,
          ),
        ],
      );
      laptop.feature.answer((await offer()).id, accept: true);
      await until(() => partFiles(inbox).isNotEmpty);
      await until(() => (onLaptop()?.bytesDone ?? 0) > 0);

      await laptop.feature.cancel(laptop.transfers.single.id);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      gate.complete();

      expect(await sending, QuickShareSendResult.cancelledByReceiver);
      expect(onLaptop()?.status, TransferStatus.cancelled);
      expect(partFiles(inbox), isEmpty);
      expect(File(p.join(inbox.path, 'big.bin')).existsSync(), isFalse);
    });

    test('the phone cancelling mid-file leaves nothing behind', () async {
      final gate = Completer<void>();
      await laptop.quickShare.receiveForAWhile();
      final sending = phone.send(
        files: [
          gatedPhoneFile(
            'big.bin',
            _bytes(64 * 1024, 1),
            _bytes(10, 2),
            gate.future,
          ),
        ],
      );
      laptop.feature.answer((await offer()).id, accept: true);
      await until(() => (onLaptop()?.bytesDone ?? 0) > 0);

      await phone.cancel();
      gate.complete();

      expect(await sending, QuickShareSendResult.cancelled);
      await until(() => onLaptop()?.status == TransferStatus.cancelled);
      expect(onLaptop()?.failure, TransferFailure.cancelledByPeer);
      await until(() => partFiles(inbox).isEmpty);
      expect(File(p.join(inbox.path, 'big.bin')).existsSync(), isFalse);
    });

    test('hiding the device declines what was waiting', () async {
      await laptop.quickShare.receiveForAWhile();
      final sending = phone.send(files: [phoneFile('a.bin', _bytes(100, 1))]);
      await offer();

      await laptop.quickShare.stopReceiving();

      expect(
        await sending,
        anyOf(
          QuickShareSendResult.declined,
          QuickShareSendResult.cancelledByReceiver,
        ),
      );
      expect(onLaptop()?.status, TransferStatus.cancelled);
      expect(onLaptop()?.needsAnswer, isFalse);
      expect(laptop.quickShare.receiveState.isOn, isFalse);
    });

    test('a running transfer outlives the visibility window', () async {
      await laptop.feature.stop();
      laptop = await SoloDevice.start(
        'Laptop',
        inbox,
        quickShare: QuickShareOptions(
          bindAddress: InternetAddress.loopbackIPv4,
          advertise: false,
          receiveWindow: const Duration(milliseconds: 300),
          timeouts: loopbackQuickShare.timeouts,
        ),
      );
      phone = QuickSharePhone(laptop);
      final gate = Completer<void>();
      await laptop.quickShare.receiveForAWhile();
      final sending = phone.send(
        files: [
          gatedPhoneFile(
            'big.bin',
            _bytes(1024, 1),
            _bytes(10, 2),
            gate.future,
          ),
        ],
      );
      laptop.feature.answer((await offer()).id, accept: true);

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(laptop.quickShare.receiveState.isOn, isTrue);
      expect(
        laptop.quickShare.receiveState.remaining(DateTime.now()),
        Duration.zero,
      );
      gate.complete();

      expect(await sending, QuickShareSendResult.sent);
      await until(() => onLaptop()?.status == TransferStatus.done);
      expect(File(p.join(inbox.path, 'big.bin')).existsSync(), isTrue);
    });
  });
}
