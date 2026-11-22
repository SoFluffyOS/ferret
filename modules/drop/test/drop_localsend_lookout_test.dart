import 'dart:io';

import 'package:drop/drop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interop_localsend/interop_localsend.dart';

import 'support/files.dart';
import 'support/localsend_devices.dart';

/// LocalSend 1.18 and newer answer an announcement only by calling
/// `/register` on the port it names, never over multicast. A device that
/// looks for them without receiving must still hear that call.
void main() {
  late LocalSendIdentity ferretIdentity;
  late LocalSendIdentity colleagueIdentity;
  late Directory inbox;
  late Directory outbox;
  late SoloDevice ferret;
  late SoloDevice colleague;
  late LocalSendClient client;

  setUpAll(() async {
    ferretIdentity = await LocalSendIdentity.generate();
    colleagueIdentity = await LocalSendIdentity.generate();
  });

  setUp(() async {
    inbox = await Directory.systemTemp.createTemp('ferret_lookout_in');
    outbox = await Directory.systemTemp.createTemp('ferret_lookout_out');
    ferret = await SoloDevice.start(
      'Ferret',
      outbox,
      identity: ferretIdentity,
      options: const LocalSendOptions(
        port: 0,
        useMulticast: false,
        scanAddresses: false,
        multicastWait: Duration(seconds: 2),
        hearsRegisters: true,
      ),
    );
    colleague = await SoloDevice.start(
      'Colleague PC',
      inbox,
      identity: colleagueIdentity,
    );
    await colleague.localSend.receiveForAWhile();
    client = LocalSendClient(identity: colleagueIdentity);
  });

  tearDown(() async {
    client.close();
    await colleague.feature.stop();
    await ferret.feature.stop();
    await inbox.delete(recursive: true);
    await outbox.delete(recursive: true);
  });

  LocalSendInfo colleagueInfo() => LocalSendInfo(
    alias: 'Colleague PC',
    fingerprint: colleagueIdentity.fingerprint,
    deviceModel: 'Windows',
    port: colleague.localSend.receiveState.port,
    protocol: LocalSendDefaults.https,
  );

  LocalSendPeer ferretAt(int port) => LocalSendPeer(
    info: LocalSendInfo(
      alias: 'Ferret',
      fingerprint: ferretIdentity.fingerprint,
      port: port,
      protocol: LocalSendDefaults.https,
    ),
    address: InternetAddress.loopbackIPv4,
    lastSeen: DateTime.now(),
  );

  Future<int> lookoutWhileScanning(Future<void> scan) async {
    await until(() => ferret.localSend.lookoutPort != null);
    return ferret.localSend.lookoutPort!;
  }

  test('a newer LocalSend that answers with /register is listed, '
      'and the answer is refused so it does not list this device', () async {
    final scan = ferret.localSend.scan();
    final port = await lookoutWhileScanning(scan);

    await expectLater(
      client.register(ferretAt(port), colleagueInfo()),
      throwsA(
        isA<LocalSendException>().having(
          (error) => error.failure,
          'failure',
          LocalSendFailure.rejected,
        ),
      ),
    );
    await scan;

    final deviceId = LocalSendIds.deviceId(colleagueIdentity.fingerprint);
    expect(ferret.localSend.peerFor(deviceId), isNotNull);
    expect(ferret.localSend.lookoutPort, isNull);
    expect(ferret.localSend.receiveState.isOn, isFalse);

    final file = await randomFile(outbox, 'notes.pdf', 4096);
    final sent = await ferret.feature.sendFiles(deviceId, [file.path]);
    expect(sent?.isLocalSend, isTrue);
    await until(() => colleague.transfers.firstOrNull?.needsAnswer ?? false);
    colleague.feature.answer(colleague.transfers.first.id, accept: true);
    await until(() => colleague.transfers.first.status == .done);
  });

  test('nobody can send through the lookout', () async {
    final scan = ferret.localSend.scan();
    final port = await lookoutWhileScanning(scan);

    final offer = PrepareUploadRequest(
      info: colleagueInfo(),
      files: const {
        'a': LocalSendFile(id: 'a', fileName: 'a.txt', size: 3),
      },
    );
    await expectLater(
      client.prepareUpload(ferretAt(port), offer),
      throwsA(
        isA<LocalSendException>().having(
          (error) => error.failure,
          'failure',
          LocalSendFailure.rejected,
        ),
      ),
    );
    await expectLater(
      client.info(ferretAt(port)),
      throwsA(isA<LocalSendException>()),
    );
    await scan;
    expect(ferret.transfers, isEmpty);
  });

  test('receiving takes over from the lookout', () async {
    final scan = ferret.localSend.scan();
    await lookoutWhileScanning(scan);

    await ferret.localSend.receiveForAWhile();
    expect(ferret.localSend.lookoutPort, isNull);
    expect(ferret.localSend.receiveState.isOn, isTrue);
    await scan;
    expect(ferret.localSend.receiveState.isOn, isTrue);
  });
}
