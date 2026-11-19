import 'dart:io';

import 'package:drop/drop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interop_localsend/interop_localsend.dart';
import 'package:path/path.dart' as p;

import 'support/files.dart';
import 'support/localsend_devices.dart';

void main() {
  late LocalSendIdentity laptopIdentity;
  late LocalSendIdentity phoneIdentity;
  late Directory inbox;
  late Directory outbox;
  late SoloDevice laptop;
  late SoloDevice phone;

  setUpAll(() async {
    laptopIdentity = await LocalSendIdentity.generate();
    phoneIdentity = await LocalSendIdentity.generate();
  });

  setUp(() async {
    inbox = await Directory.systemTemp.createTemp('ferret_localsend_in');
    outbox = await Directory.systemTemp.createTemp('ferret_localsend_out');
    laptop = await SoloDevice.start('Laptop', inbox, identity: laptopIdentity);
    phone = await SoloDevice.start('Phone', outbox, identity: phoneIdentity);
  });

  tearDown(() async {
    await phone.feature.stop();
    await laptop.feature.stop();
    await inbox.delete(recursive: true);
    await outbox.delete(recursive: true);
  });

  /// Turns receiving on on the laptop and lets the phone find it.
  Future<String> connect() async {
    await laptop.localSend.receiveForAWhile();
    final found = await phone.localSend.findAt(
      InternetAddress.loopbackIPv4,
      port: laptop.localSend.receiveState.port,
    );
    expect(found, isTrue);
    return LocalSendIds.deviceId(laptopIdentity.fingerprint);
  }

  Transfer? onLaptop() => laptop.transfers.firstOrNull;

  Transfer? onPhone() => phone.transfers.firstOrNull;

  group('receiving', () {
    test('is off until someone turns it on', () async {
      expect(laptop.localSend.receiveState.isOn, isFalse);
      expect(laptop.localSend.receiveState.port, isNull);
      expect(laptop.localSend.peers, isEmpty);
    });

    test('turns on for 10 minutes, with the time left', () async {
      await laptop.localSend.receiveForAWhile();

      final state = laptop.localSend.receiveState;
      expect(state.isOn, isTrue);
      expect(state.alias, 'Laptop');
      expect(state.problem, isNull);
      final left = state.remaining(DateTime.now()) ?? Duration.zero;
      expect(left.inSeconds, inInclusiveRange(595, 600));

      await laptop.localSend.stopReceiving();
      expect(laptop.localSend.receiveState.isOn, isFalse);
      expect(laptop.localSend.receiveState.remaining(DateTime.now()), isNull);
    });

    test('turns itself off when the window ends', () async {
      await laptop.feature.stop();
      laptop = await SoloDevice.start(
        'Laptop',
        inbox,
        identity: laptopIdentity,
        options: const LocalSendOptions(
          port: 0,
          useMulticast: false,
          receiveWindow: Duration(milliseconds: 80),
        ),
      );

      await laptop.localSend.receiveForAWhile();
      expect(laptop.localSend.receiveState.isOn, isTrue);

      await until(() => !laptop.localSend.receiveState.isOn);
      expect(
        laptop.settings.get<bool>(DropSettings.localSendReceiveAlways),
        isNull,
      );
    });

    test('set to stay on, it comes back after a restart', () async {
      await laptop.localSend.setReceiveAlways(true);
      expect(laptop.localSend.receiveState.isOn, isTrue);
      expect(laptop.localSend.receiveState.until, isNull);
      await laptop.feature.stop();

      laptop = await SoloDevice.start(
        'Laptop',
        inbox,
        identity: laptopIdentity,
        settings: {DropSettings.localSendReceiveAlways: true},
      );

      await until(() => laptop.localSend.receiveState.isOn);
      expect(laptop.localSend.receiveState.until, isNull);
    });

    test('turning LocalSend off stops receiving and forgets devices', () async {
      await connect();
      await laptop.localSend.setReceiveAlways(true);

      await laptop.localSend.setEnabled(false);

      expect(laptop.localSend.receiveState.isOn, isFalse);
      expect(laptop.localSend.receiveAlways, isFalse);
      await laptop.localSend.receiveForAWhile();
      expect(laptop.localSend.receiveState.isOn, isFalse);

      await phone.localSend.setEnabled(false);
      expect(phone.localSend.peers, isEmpty);
    });

    test('the certificate is made once and kept', () async {
      await laptop.feature.stop();
      laptop = await SoloDevice.start('Laptop', inbox);

      await laptop.localSend.receiveForAWhile();

      final stored = await laptop.secrets.read('drop.localsend_identity');
      expect(
        LocalSendIdentity.decode(stored ?? '')?.fingerprint,
        hasLength(64),
      );
    });
  });

  group('a transfer between two devices', () {
    test('asks first, then several files arrive intact', () async {
      final target = await connect();
      final photo = await randomFile(outbox, 'photo.jpg', 200 * 1024);
      final notes = await randomFile(outbox, 'notes.txt', 3000);
      await File(p.join(inbox.path, 'photo.jpg')).writeAsString('mine');

      final sent = await phone.feature.sendFiles(target, [
        photo.path,
        notes.path,
      ]);
      expect(sent?.deviceName, 'Laptop (LocalSend)');
      expect(sent?.isLocalSend, isTrue);

      await until(() => onLaptop()?.needsAnswer ?? false);
      final offer = onLaptop();
      expect(offer?.deviceName, 'Phone (LocalSend)');
      expect(offer?.status, TransferStatus.waiting);
      expect(offer?.localSend?.fingerprint, phoneIdentity.fingerprint);
      expect(offer?.localSend?.deviceModel, 'macOS');
      expect(offer?.localSend?.address, '127.0.0.1');
      expect(
        [for (final file in offer?.files ?? []) file.name],
        [
          'photo.jpg',
          'notes.txt',
        ],
      );
      expect(offer?.totalBytes, 200 * 1024 + 3000);
      expect(inbox.listSync(), hasLength(1));
      expect(onPhone()?.status, TransferStatus.waiting);

      laptop.feature.answer(offer?.id ?? '', accept: true);
      await until(() => onLaptop()?.status == .done);
      await until(() => onPhone()?.status == .done);

      final received = onLaptop();
      expect(received?.files.first.name, 'photo (1).jpg');
      expect(
        await File(received?.files.first.location ?? '').readAsBytes(),
        await photo.readAsBytes(),
      );
      expect(
        await File(p.join(inbox.path, 'notes.txt')).readAsBytes(),
        await notes.readAsBytes(),
      );
      expect(
        await File(p.join(inbox.path, 'photo.jpg')).readAsString(),
        'mine',
      );
      expect(partFiles(inbox), isEmpty);
      expect(received?.bytesDone, received?.totalBytes);
      expect(onPhone()?.bytesDone, onPhone()?.totalBytes);
      expect(laptop.feature.canRetry(received ?? fail('no transfer')), isFalse);
    });

    test('a folder goes as its tree, into a new folder', () async {
      final target = await connect();
      final album = await Directory(
        p.join(outbox.path, 'Album', 'Day 1'),
      ).create(recursive: true);
      final photo = await randomFile(album, 'a.jpg', 3000);
      await Directory(p.join(inbox.path, 'Album')).create();

      await phone.feature.sendFiles(target, [p.dirname(album.path)]);
      await until(() => onLaptop()?.needsAnswer ?? false);
      expect(onLaptop()?.folderName, 'Album');
      laptop.feature.answer(onLaptop()?.id ?? '', accept: true);
      await until(() => onLaptop()?.status == .done);

      final saved = File(p.join(inbox.path, 'Album (2)', 'Day 1', 'a.jpg'));
      expect(onLaptop()?.folderName, 'Album (2)');
      expect(await saved.readAsBytes(), await photo.readAsBytes());
      expect(
        saved.lastModifiedSync().difference(photo.lastModifiedSync()).abs(),
        lessThan(const Duration(seconds: 1)),
      );
    });

    test('a declined offer saves nothing, and the sender is told', () async {
      final target = await connect();
      final photo = await randomFile(outbox, 'photo.jpg', 4096);

      await phone.feature.sendFiles(target, [photo.path]);
      await until(() => onLaptop()?.needsAnswer ?? false);
      laptop.feature.answer(onLaptop()?.id ?? '', accept: false);

      await until(() => onPhone()?.status == .failed);
      expect(onPhone()?.failure, TransferFailure.declined);
      expect(onLaptop()?.status, TransferStatus.cancelled);
      expect(onLaptop()?.failure, TransferFailure.declined);
      expect(onLaptop()?.needsAnswer, isFalse);
      expect(inbox.listSync(), isEmpty);
      expect(phone.feature.canRetry(onPhone() ?? fail('no transfer')), isTrue);
    });

    test('an offer nobody answers times out', () async {
      await laptop.feature.stop();
      laptop = await SoloDevice.start(
        'Laptop',
        inbox,
        identity: laptopIdentity,
        options: const LocalSendOptions(
          port: 0,
          useMulticast: false,
          answerTimeout: Duration(milliseconds: 80),
        ),
      );
      final target = await connect();
      final photo = await randomFile(outbox, 'photo.jpg', 4096);

      await phone.feature.sendFiles(target, [photo.path]);

      await until(() => onLaptop()?.status == .failed);
      expect(onLaptop()?.failure, TransferFailure.timedOut);
      await until(() => onPhone()?.failure == .declined);
    });

    test('the sender cancels while the receiver still decides', () async {
      final target = await connect();
      final photo = await randomFile(outbox, 'photo.jpg', 4096);

      final sent = await phone.feature.sendFiles(target, [photo.path]);
      await until(() => onLaptop()?.needsAnswer ?? false);
      await phone.feature.cancel(sent?.id ?? '');

      expect(onPhone()?.status, TransferStatus.cancelled);
      await until(() => onLaptop()?.status == .cancelled);
      expect(onLaptop()?.failure, TransferFailure.cancelledByPeer);
      expect(onLaptop()?.needsAnswer, isFalse);
      expect(inbox.listSync(), isEmpty);
    });

    test('cancelling an offer on the receiver declines it', () async {
      final target = await connect();
      final photo = await randomFile(outbox, 'photo.jpg', 4096);

      await phone.feature.sendFiles(target, [photo.path]);
      await until(() => onLaptop()?.needsAnswer ?? false);
      await laptop.feature.cancel(onLaptop()?.id ?? '');

      await until(() => onPhone()?.failure == .declined);
      expect(onLaptop()?.status, TransferStatus.cancelled);
    });

    test('turning receiving off declines what waits', () async {
      final target = await connect();
      final photo = await randomFile(outbox, 'photo.jpg', 4096);

      await phone.feature.sendFiles(target, [photo.path]);
      await until(() => onLaptop()?.needsAnswer ?? false);
      await laptop.localSend.stopReceiving();

      expect(onLaptop()?.status, TransferStatus.cancelled);
      await until(() => onPhone()?.status == .failed);
    });

    test('text is only shown once accepted', () async {
      final target = await connect();

      final sent = phone.localSend.sendText(target, 'Door code 4321');
      await until(() => onLaptop()?.needsAnswer ?? false);
      expect(onLaptop()?.isText, isTrue);
      expect(onLaptop()?.text, isNull);

      laptop.feature.answer(onLaptop()?.id ?? '', accept: true);
      await until(() => onLaptop()?.status == .done);
      await until(() => onPhone()?.status == .done);

      expect(onLaptop()?.text, 'Door code 4321');
      expect(sent?.text, 'Door code 4321');
      expect(inbox.listSync(), isEmpty);
    });

    test('a device that left the network is not sent to', () async {
      final target = await connect();
      final photo = await randomFile(outbox, 'photo.jpg', 4096);
      await laptop.localSend.stopReceiving();

      await phone.feature.sendFiles(target, [photo.path]);
      await until(() => onPhone()?.status == .failed);
      expect(onPhone()?.failure, TransferFailure.unreachable);

      final unknown = await phone.feature.sendFiles(
        LocalSendIds.deviceId('ffff'),
        [photo.path],
      );
      expect(unknown, isNull);
    });
  });

  group('a receiver protected by a PIN', () {
    late LocalSendServer server;

    setUp(() async {
      server = LocalSendServer(
        identity: laptopIdentity,
        self: (port) => LocalSendInfo(
          alias: 'Guarded',
          fingerprint: laptopIdentity.fingerprint,
          port: port,
          protocol: 'https',
        ),
        delegate: _AcceptAll(inbox),
        port: 0,
        fallbackPorts: 0,
        pin: () => '2468',
        address: InternetAddress.loopbackIPv4,
      );
      await server.start();
    });

    tearDown(() => server.stop());

    test('asks for the PIN, then sends with it', () async {
      await phone.localSend.findAt(
        InternetAddress.loopbackIPv4,
        port: server.boundPort,
      );
      final photo = await randomFile(outbox, 'photo.jpg', 4096);

      await phone.feature.sendFiles(
        LocalSendIds.deviceId(laptopIdentity.fingerprint),
        [photo.path],
      );
      await until(() => onPhone()?.status == .failed);
      final failed = onPhone() ?? fail('no transfer');
      expect(failed.failure, TransferFailure.pinRequired);
      expect(phone.feature.needsPin(failed), isTrue);
      expect(phone.feature.canRetry(failed), isFalse);

      await phone.feature.retryWithPin(failed.id, '2468');
      await until(() => onPhone()?.status == .done);

      expect(
        await File(p.join(inbox.path, 'photo.jpg')).readAsBytes(),
        await photo.readAsBytes(),
      );
      expect(phone.feature.needsPin(onPhone() ?? failed), isFalse);
    });
  });
}

class _AcceptAll implements LocalSendReceiveDelegate {
  _AcceptAll(this.folder);

  final Directory folder;

  @override
  Future<Set<String>?> onOffer(LocalSendOffer offer) async => {
    for (final file in offer.files) file.id,
  };

  @override
  Future<File> partFile(LocalSendOffer offer, LocalSendFile file) async =>
      File(p.join(folder.path, '${file.id}.part'));

  @override
  void onProgress(LocalSendOffer offer, int receivedBytes) {}

  @override
  Future<void> onFileReceived(
    LocalSendOffer offer,
    LocalSendFile file,
    File part,
  ) => part.rename(p.join(folder.path, file.fileName));

  @override
  void onSessionEnded(LocalSendOffer offer, LocalSendSessionEnd end) {}
}
