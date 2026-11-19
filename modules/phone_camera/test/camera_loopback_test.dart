@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_camera/ferret_camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_camera/phone_camera.dart';
import 'package:protocol/protocol.dart';

import 'helpers/fakes.dart';
import 'helpers/memory_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryDiscoveryBus bus;
  late Directory files;
  final engines = <FerretEngine>[];

  setUp(() async {
    bus = MemoryDiscoveryBus();
    files = await Directory.systemTemp.createTemp('camera_test');
  });

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
    await files.delete(recursive: true);
  });

  Future<FerretEngine> startEngine(
    String name,
    CameraFeature feature, {
    FormFactor formFactor = .FORM_FACTOR_LAPTOP,
  }) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: formFactor,
      ),
      features: [feature],
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<void> until(bool Function() condition) async {
    for (var attempt = 0; attempt < 300; attempt++) {
      if (condition()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    fail('Timed out waiting');
  }

  Future<File> picture(String name) async {
    final file = File('${files.path}/$name');
    await file.writeAsBytes([0xff, 0xd8, 0xff, 1, 2, 3]);
    return file;
  }

  Future<
    ({
      CameraFeature computer,
      CameraFeature phone,
      FakePhoneCamera camera,
      FakeTransfers computerTransfers,
      FakeTransfers phoneTransfers,
      FakePaste paste,
      String phoneId,
    })
  >
  setUpPair({
    bool scansDocuments = false,
    Duration askFor = const Duration(minutes: 5),
  }) async {
    final camera = FakePhoneCamera(scansDocuments: scansDocuments);
    final computerTransfers = FakeTransfers();
    final phoneTransfers = FakeTransfers();
    final paste = FakePaste();
    final computer = CameraFeature(
      camera: const UnsupportedPhoneCamera(),
      transfers: computerTransfers,
      paste: paste,
    );
    final phone = CameraFeature(
      camera: camera,
      transfers: phoneTransfers,
      askFor: askFor,
    );
    final laptop = await startEngine('MacBook Air', computer);
    final pixel = await startEngine(
      'Pixel 7',
      phone,
      formFactor: .FORM_FACTOR_PHONE,
    );

    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The pairing offer should parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await pixel.pairWithOffer(offer), isA<Paired>());
    await until(() => laptop.sessions.isNotEmpty && pixel.sessions.isNotEmpty);

    return (
      computer: computer,
      phone: phone,
      camera: camera,
      computerTransfers: computerTransfers,
      phoneTransfers: phoneTransfers,
      paste: paste,
      phoneId: laptop.sessions.single.remoteDeviceId,
    );
  }

  test('a photo goes from the shutter to the computer\'s clipboard', () async {
    final pair = await setUpPair();

    final job = await pair.computer.request(pair.phoneId);
    expect(job.status, CaptureJobStatus.asking);
    await until(() => pair.phone.asks.isNotEmpty);
    expect(pair.phone.asks.single.kind, PictureKind.photo);

    final taking = pair.phone.take(pair.phone.asks.single.requestId);
    await until(() => pair.camera.isOpen);
    final shot = await picture('shot.jpg');
    pair.camera.press(shot.path);
    await taking;

    expect(pair.phoneTransfers.sent.single.$2, shot.path);
    expect(pair.phone.asks, isEmpty);
    await until(() => pair.computerTransfers.isFollowing('transfer-1'));
    expect(pair.computer.jobs[job.id]?.status, CaptureJobStatus.receiving);

    final received = await picture('received.jpg');
    pair.computerTransfers.finish('transfer-1', [received.path]);
    await until(() => pair.computer.jobs[job.id]?.status == .done);

    final done = pair.computer.jobs[job.id];
    expect(done?.onClipboard, isTrue);
    expect(done?.paths, [received.path]);
    expect(pair.paste.images.single.$2, 'image/jpeg');
    expect(pair.paste.images.single.$1, await received.readAsBytes());
  });

  test('nothing is captured until the owner answers', () async {
    final pair = await setUpPair();

    await pair.computer.request(pair.phoneId);
    await until(() => pair.phone.asks.isNotEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(pair.camera.opened, 0);
    expect(pair.phoneTransfers.sent, isEmpty);
  });

  test('Not now tells the computer and opens no camera', () async {
    final pair = await setUpPair();

    final job = await pair.computer.request(pair.phoneId);
    await until(() => pair.phone.asks.isNotEmpty);
    await pair.phone.decline(pair.phone.asks.single.requestId);
    await until(() => pair.computer.jobs[job.id]?.status == .declined);

    expect(pair.camera.opened, 0);
    expect(pair.phone.asks, isEmpty);
    expect(pair.paste.images, isEmpty);
  });

  test('closing the camera without a photo says so', () async {
    final pair = await setUpPair();

    final job = await pair.computer.request(pair.phoneId);
    await until(() => pair.phone.asks.isNotEmpty);
    final taking = pair.phone.take(pair.phone.asks.single.requestId);
    await until(() => pair.camera.isOpen);
    pair.camera.close();
    await taking;
    await until(() => pair.computer.jobs[job.id]?.status == .cancelled);

    expect(pair.phoneTransfers.sent, isEmpty);
  });

  test('a camera the phone refuses reads as no permission', () async {
    final pair = await setUpPair();

    final job = await pair.computer.request(pair.phoneId);
    await until(() => pair.phone.asks.isNotEmpty);
    final taking = pair.phone.take(pair.phone.asks.single.requestId);
    await until(() => pair.camera.isOpen);
    pair.camera.close(.noPermission);
    await taking;

    await until(() => pair.computer.jobs[job.id]?.status == .noPermission);
  });

  test('Cancel on the computer takes the request away and throws away a '
      'photo taken after it', () async {
    final pair = await setUpPair();

    final job = await pair.computer.request(pair.phoneId);
    await until(() => pair.phone.asks.isNotEmpty);
    final taking = pair.phone.take(pair.phone.asks.single.requestId);
    await until(() => pair.camera.isOpen);

    await pair.computer.cancel(job.id);
    await until(() => pair.phone.asks.isEmpty);
    final late = await picture('late.jpg');
    pair.camera.press(late.path);
    await taking;

    expect(pair.computer.jobs[job.id], isNull);
    expect(pair.phoneTransfers.sent, isEmpty);
    expect(late.existsSync(), isFalse);
  });

  test('a new request takes the place of the one before', () async {
    final pair = await setUpPair();

    final first = await pair.computer.request(pair.phoneId);
    await until(() => pair.phone.asks.isNotEmpty);
    final second = await pair.computer.request(pair.phoneId);
    await until(() => pair.phone.asks.single.requestId == second.id);

    expect(pair.computer.jobs[first.id], isNull);
    expect(pair.computer.jobs[second.id]?.status, CaptureJobStatus.asking);
  });

  test('an Android phone offers no document scan', () async {
    final pair = await setUpPair();

    final job = await pair.computer.request(pair.phoneId, kind: .document);

    expect(job.status, CaptureJobStatus.unsupported);
    expect(pair.phone.asks, isEmpty);
  });

  test('an iPhone scans documents', () async {
    final pair = await setUpPair(scansDocuments: true);

    final job = await pair.computer.request(pair.phoneId, kind: .document);
    await until(() => pair.phone.asks.isNotEmpty);

    expect(job.status, CaptureJobStatus.asking);
    expect(pair.phone.asks.single.kind, PictureKind.document);
  });

  test('a scan of several pages is saved, not put on the clipboard', () async {
    final pair = await setUpPair(scansDocuments: true);

    final job = await pair.computer.request(pair.phoneId, kind: .document);
    await until(() => pair.phone.asks.isNotEmpty);
    final taking = pair.phone.take(pair.phone.asks.single.requestId);
    await until(() => pair.camera.isOpen);
    final scan = await picture('scan.pdf');
    pair.camera.press(scan.path, mimeType: 'application/pdf');
    await taking;
    await until(() => pair.computerTransfers.isFollowing('transfer-1'));
    pair.computerTransfers.finish('transfer-1', [scan.path]);
    await until(() => pair.computer.jobs[job.id]?.status == .done);

    expect(pair.computer.jobs[job.id]?.onClipboard, isFalse);
    expect(pair.paste.images, isEmpty);
  });

  test('a request nobody answers expires on both sides', () async {
    final pair = await setUpPair(askFor: const Duration(milliseconds: 100));

    final job = await pair.computer.request(pair.phoneId);
    await until(() => pair.phone.asks.isNotEmpty);
    await until(() => pair.phone.asks.isEmpty);
    await until(() => pair.computer.jobs[job.id]?.status == .expired);

    expect(pair.camera.opened, 0);
  });

  test('a phone that went offline ends the wait', () async {
    final pair = await setUpPair();

    final job = await pair.computer.request(pair.phoneId);
    await until(() => pair.phone.asks.isNotEmpty);
    await engines.last.stop();
    engines.removeLast();
    await until(() => pair.computer.jobs[job.id]?.status == .offline);
  });

  test('a transfer that fails ends the line', () async {
    final pair = await setUpPair();

    final job = await pair.computer.request(pair.phoneId);
    await until(() => pair.phone.asks.isNotEmpty);
    final taking = pair.phone.take(pair.phone.asks.single.requestId);
    await until(() => pair.camera.isOpen);
    pair.camera.press((await picture('shot.jpg')).path);
    await taking;
    await until(() => pair.computerTransfers.isFollowing('transfer-1'));
    pair.computerTransfers.fail('transfer-1');

    await until(() => pair.computer.jobs[job.id]?.status == .failed);
    expect(pair.paste.images, isEmpty);
  });

  test('flags say who takes and who asks', () {
    expect(CameraFeature(camera: FakePhoneCamera()).flags, ['photo']);
    expect(
      CameraFeature(camera: FakePhoneCamera(scansDocuments: true)).flags,
      ['photo', 'document'],
    );
    expect(
      CameraFeature(camera: const UnsupportedPhoneCamera()).flags,
      ['request'],
    );
  });
}
