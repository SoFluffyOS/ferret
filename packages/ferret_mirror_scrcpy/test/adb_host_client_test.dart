import 'dart:io';
import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_adb_server.dart';

void main() {
  late FakeAdbServer server;
  late AdbHostClient adb;

  setUp(() async {
    server = await FakeAdbServer.start();
    adb = AdbHostClient(port: server.port);
  });

  tearDown(() => server.stop());

  test('knows whether a server is running', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final freePort = closed.port;
    await closed.close();

    expect(await adb.isRunning(), isTrue);
    expect(await AdbHostClient(port: freePort).isRunning(), isFalse);
    expect(server.requests, ['host:version']);
  });

  test('lists devices from host:devices-l', () async {
    server.deviceList =
        'emulator-5554          device product:sdk model:Pixel_9 transport_id:1\n'
        'ABC123                 unauthorized transport_id:2\n';

    final devices = await adb.devices();

    expect(devices.map((device) => device.serial), ['emulator-5554', 'ABC123']);
    expect(devices.first.name, 'Pixel 9');
    expect(devices.last.state, AdbDeviceState.unauthorized);
  });

  test('runs a shell command on the device it asked for', () async {
    final output = await adb.shell('GOOD', ['echo', 'hi']);

    expect(output, 'hi');
    expect(server.requests, ['host:transport:GOOD', 'shell:echo hi']);
  });

  test('gives a running command\'s lines, and says when it ended', () async {
    final shell = await adb.startShell('GOOD', ['two', 'lines']);

    expect(await shell.lines.toList(), ['first', 'second']);
    await shell.done;
  });

  test('throws adb\'s reason when the device is gone', () async {
    expect(
      adb.shell('GONE', ['echo', 'hi']),
      throwsA(
        isA<AdbException>().having(
          (error) => error.message,
          'message',
          contains('host:transport:GONE'),
        ),
      ),
    );
  });

  test('pushes a file through the sync service, in 64 KB pieces', () async {
    final directory = await Directory.systemTemp.createTemp('adb_push');
    addTearDown(() => directory.delete(recursive: true));
    final bytes = Uint8List.fromList(
      List.generate(150000, (index) => index % 251),
    );
    final file = File('${directory.path}/server.jar');
    await file.writeAsBytes(bytes);

    await adb.push('GOOD', file, '/data/local/tmp/server.jar');

    expect(server.requests, ['host:transport:GOOD', 'sync:']);
    expect(server.pushed.keys.single, '/data/local/tmp/server.jar,33188');
    expect(server.pushed.values.single, bytes);
  });

  test('throws the device\'s reason when a push fails', () async {
    final directory = await Directory.systemTemp.createTemp('adb_push');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/server.jar');
    await file.writeAsBytes([1, 2, 3]);
    server.pushFailure = 'Permission denied';

    expect(
      adb.push('GOOD', file, '/system/server.jar'),
      throwsA(
        isA<AdbException>().having(
          (error) => error.message,
          'message',
          contains('Permission denied'),
        ),
      ),
    );
  });

  test('opens a socket on the device, both ways', () async {
    final connection = await adb.open('GOOD', 'there');
    if (connection == null) {
      fail('The socket should have opened');
    }

    final received = <int>[];
    connection.input.listen(received.addAll);
    connection.add([1, 2, 3]);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(received, [0, 1, 2, 3]);
    connection.close();
  });

  test('gives no connection when nothing listens on the device', () async {
    expect(await adb.open('GOOD', 'nope'), isNull);
    expect(await adb.open('GONE', 'there'), isNull);
  });

  test('pairs and connects through the server', () async {
    final paired = await adb.pair('192.168.1.20:37000', '123456');
    final connected = await adb.connect('192.168.1.20:5555');

    expect(paired.succeeded, isTrue);
    expect(paired.message, contains('192.168.1.20:37000'));
    expect(connected.succeeded, isTrue);
    expect(server.requests, [
      'host:pair:123456:192.168.1.20:37000',
      'host:connect:192.168.1.20:5555',
    ]);
  });
}
