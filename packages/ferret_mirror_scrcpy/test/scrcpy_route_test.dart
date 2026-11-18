import 'dart:io';

import 'package:ferret_mirror_scrcpy/ferret_mirror_scrcpy.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_adb_server.dart';

void main() {
  const pixel = AdbDevice(serial: 'ABC123', state: .ready, model: 'Pixel_7');
  const wireless = AdbDevice(
    serial: '192.168.1.20:5555',
    state: .ready,
    model: 'Pixel_7a',
  );
  const locked = AdbDevice(serial: 'XYZ789', state: .unauthorized);

  late _FakeAdb adb;

  ScrcpyRoute route({String system = 'macos', bool hasAdb = true}) {
    return ScrcpyRoute(
      operatingSystem: system,
      pollInterval: const Duration(milliseconds: 10),
      findAdb: () async => switch (hasAdb) {
        true => adb,
        false => null,
      },
    );
  }

  setUp(() => adb = _FakeAdb());

  group('status', () {
    test('is unsupported on phones', () async {
      expect(await route(system: 'android').status(), isA<RouteUnsupported>());
      expect(await route(system: 'ios').status(), isA<RouteUnsupported>());
    });

    test('asks to install adb when there is none', () async {
      final status = await route(hasAdb: false).status();

      expect((status as RouteNeedsSetup).step, RouteSetup.installTool);
    });

    test('asks to turn on debugging when no device shows', () async {
      final status = await route().status();

      expect((status as RouteNeedsSetup).step, RouteSetup.enableDebugging);
    });

    test('asks to allow this computer, naming the device', () async {
      adb.found = [locked];

      final status = await route().status();

      expect((status as RouteNeedsSetup).step, RouteSetup.authorizeComputer);
      expect(status.detail, 'XYZ789');
    });

    test('is ready as soon as one device is', () async {
      adb.found = [locked, pixel];

      expect(await route().status(), isA<RouteReady>());
    });

    test('treats a failing adb as no device', () async {
      adb.fails = true;

      final status = await route().status();

      expect((status as RouteNeedsSetup).step, RouteSetup.enableDebugging);
    });
  });

  group('targets', () {
    test('lists ready devices only, and marks the wireless ones', () async {
      adb.found = [pixel, locked, wireless];
      final scrcpy = route();

      final targets = await scrcpy.targets.first;

      expect(targets.map((target) => target.id), [
        'ABC123',
        '192.168.1.20:5555',
      ]);
      expect(targets.map((target) => target.name), ['Pixel 7', 'Pixel 7a']);
      expect(targets.map((target) => target.wireless), [false, true]);
      expect(targets.every((target) => target.routeId == 'adb'), isTrue);
      await scrcpy.dispose();
    });

    test('are none on a phone, without asking adb', () async {
      adb.found = [pixel];
      final scrcpy = route(system: 'android');

      expect(await scrcpy.targets.first, isEmpty);
      expect(adb.calls, 0);
      await scrcpy.dispose();
    });

    test('emits again only when the list changes', () async {
      adb.found = [pixel];
      final scrcpy = route();
      final seen = <List<String>>[];
      final subscription = scrcpy.targets.listen(
        (targets) => seen.add([for (final target in targets) target.id]),
      );

      await _until(() => adb.calls >= 3);
      adb.found = [pixel, wireless];
      await _until(() => seen.length >= 2);
      adb.found = [];
      await _until(() => seen.length >= 3);

      expect(seen, [
        ['ABC123'],
        ['ABC123', '192.168.1.20:5555'],
        <String>[],
      ]);
      await subscription.cancel();
      await scrcpy.dispose();
    });

    test('gives a late listener the current list at once', () async {
      adb.found = [pixel];
      final scrcpy = route();
      final first = scrcpy.targets.listen((_) {});
      await _until(() => adb.calls >= 1);
      await Future<void>.delayed(Duration.zero);

      final late = await scrcpy.targets.first;

      expect(late.single.id, 'ABC123');
      await first.cancel();
      await scrcpy.dispose();
    });

    test('stops asking adb once nobody listens', () async {
      final scrcpy = route();
      final subscription = scrcpy.targets.listen((_) {});
      await _until(() => adb.calls >= 2);

      await subscription.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final callsAfterCancel = adb.calls;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(adb.calls, callsAfterCancel);
      await scrcpy.dispose();
    });
  });

  group('wireless debugging', () {
    test('pairs and connects through adb', () async {
      final scrcpy = route();

      final paired = await scrcpy.pair('192.168.1.20:37000', '123456');
      final connected = await scrcpy.connect('192.168.1.20:5555');

      expect(paired.succeeded, isTrue);
      expect(connected.succeeded, isTrue);
      expect(adb.commands, [
        'pair 192.168.1.20:37000 123456',
        'connect 192.168.1.20:5555',
      ]);
    });

    test('says so when adb is missing', () async {
      final result = await route(hasAdb: false).pair('host:1', '000000');

      expect(result.succeeded, isFalse);
    });
  });

  group('reaching adb', () {
    late FakeAdbServer server;
    late int freePort;

    setUp(() async {
      server = await FakeAdbServer.start();
      final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      freePort = closed.port;
      await closed.close();
    });

    tearDown(() => server.stop());

    AdbLocator locatorWith(Set<String> files) => AdbLocator(
      operatingSystem: 'macos',
      environment: const {'PATH': '/tools'},
      exists: files.contains,
    );

    test('uses adb\'s server when one is running, and no program', () async {
      server.deviceList = 'ABC123 device model:Pixel_7 transport_id:1\n';
      final scrcpy = ScrcpyRoute(
        operatingSystem: 'macos',
        hostAdb: AdbHostClient(port: server.port),
        locator: locatorWith({}),
      );

      final targets = await scrcpy.targets.first;

      expect(await scrcpy.status(), isA<RouteReady>());
      expect(targets.single.name, 'Pixel 7');
      await scrcpy.dispose();
    });

    test('asks for adb when there is no server and no program', () async {
      final scrcpy = ScrcpyRoute(
        operatingSystem: 'macos',
        environment: const {},
        hostAdb: AdbHostClient(port: freePort),
        locator: locatorWith({}),
      );

      final status = await scrcpy.status();

      expect((status as RouteNeedsSetup).step, RouteSetup.installTool);
      expect(status.detail, ScrcpyRoute.needsAdb);
      expect(scrcpy.canInstallAdb, isTrue);
    });

    test('asks to start adb when its program may not be run', () async {
      final scrcpy = ScrcpyRoute(
        operatingSystem: 'macos',
        environment: const {},
        hostAdb: AdbHostClient(port: freePort),
        locator: locatorWith({'/tools/adb'}),
      );

      final status = await scrcpy.status();

      expect((status as RouteNeedsSetup).step, RouteSetup.installTool);
      expect(status.detail, ScrcpyRoute.needsAdbStarted);
    });

    test('never offers to download adb inside the App Sandbox', () async {
      final scrcpy = ScrcpyRoute(
        operatingSystem: 'macos',
        environment: const {'APP_SANDBOX_CONTAINER_ID': 'io.sofluffy.ferret'},
        hostAdb: AdbHostClient(port: freePort),
        locator: locatorWith({}),
      );

      final status = await scrcpy.status();

      expect(scrcpy.isSandboxed, isTrue);
      expect(scrcpy.canInstallAdb, isFalse);
      expect((status as RouteNeedsSetup).detail, ScrcpyRoute.needsAdbStarted);
      expect(scrcpy.installAdb(), throwsStateError);
    });
  });

  test('open refuses without adb', () async {
    const target = MirrorTarget(routeId: 'adb', id: 'ABC123', name: 'Pixel 7');

    expect(
      route(hasAdb: false).open(target, const FeedOptions(codecs: [.h264])),
      throwsStateError,
    );
  });
}

Future<void> _until(bool Function() isTrue) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!isTrue()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Waited too long');
    }

    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

class _FakeAdb extends AdbClient {
  _FakeAdb() : super('adb');

  List<AdbDevice> found = [];
  bool fails = false;
  int calls = 0;
  final List<String> commands = [];

  @override
  Future<List<AdbDevice>> devices() async {
    calls++;
    if (fails) {
      throw const AdbException('no adb server');
    }

    return found;
  }

  @override
  Future<AdbResult> pair(String address, String code) async {
    commands.add('pair $address $code');
    return const AdbResult(succeeded: true, message: 'Successfully paired');
  }

  @override
  Future<AdbResult> connect(String address) async {
    commands.add('connect $address');
    return const AdbResult(succeeded: true, message: 'connected');
  }
}
