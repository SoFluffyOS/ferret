import 'dart:io';
import 'dart:typed_data';

import 'package:dbus/dbus.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_bluez.dart';

void main() {
  late FakeBluez bluez;
  late BluezTransport transport;
  final started = <String>[];

  Future<void> start({bool connected = true}) async {
    bluez = await FakeBluez.start(connected: connected);
    started.clear();
    transport = BluezTransport(
      connect: bluez.connect,
      resolveTimeout: const Duration(milliseconds: 600),
      startSettings: (executable, arguments) async {
        started.add(executable);
        if (executable != 'blueman-manager') {
          throw const ProcessException('missing', []);
        }

        return Process.start('true', const []);
      },
    );
    addTearDown(() async {
      await transport.dispose();
      await bluez.stop();
    });
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('is ready with a powered adapter, off without power', () async {
    await start();

    final ready = await transport.status();
    bluez.adapter.interfaces['org.bluez.Adapter1']?['Powered'] =
        const DBusBoolean(false);
    final off = await transport.status();

    expect(ready, BluetoothStatus.ready);
    expect(off, BluetoothStatus.off);
  });

  test('is unsupported when BlueZ is not there', () async {
    final server = DBusServer();
    final directory = await Directory.systemTemp.createTemp('no-bluez');
    final address = await server.listenAddress(
      DBusAddress.unix(dir: directory),
    );
    final lonely = BluezTransport(connect: () => FakeBluez.clientFor(address));
    addTearDown(() async {
      await lonely.dispose();
      await server.close();
      await directory.delete(recursive: true);
    });

    expect(await lonely.status(), BluetoothStatus.unsupported);
  });

  test('lists paired devices only', () async {
    await start();

    final devices = await transport.devices();

    expect(devices.single.id, FakeBluez.iphonePath);
    expect(devices.single.name, 'Simon’s iPhone');
    expect(devices.single.connected, isTrue);
  });

  test('finds both Apple services on a connected iPhone', () async {
    await start();

    final services = await transport.connect(FakeBluez.iphonePath);

    expect(services.hasAncs, isTrue);
    expect(services.hasAms, isTrue);
    expect(bluez.iphone.calls, isEmpty);
  });

  test('asks BlueZ to connect when the iPhone is not', () async {
    await start(connected: false);
    bluez.iphone.onCall = (call) {
      bluez.iphone.interfaces['org.bluez.Device1']
        ?..['Connected'] = const DBusBoolean(true)
        ..['ServicesResolved'] = const DBusBoolean(true);
      return DBusMethodSuccessResponse();
    };

    final services = await transport.connect(FakeBluez.iphonePath);

    expect(bluez.iphone.calls, ['Connect']);
    expect(services.hasAncs, isTrue);
  });

  test('an iPhone out of reach fails as not connected', () async {
    await start(connected: false);
    bluez.iphone.onCall = (_) =>
        DBusMethodErrorResponse('org.bluez.Error.ConnectionAttemptFailed');

    await expectLater(
      transport.connect(FakeBluez.iphonePath),
      throwsA(
        isA<GattException>().having(
          (error) => error.failure,
          'failure',
          GattFailure.notConnected,
        ),
      ),
    );
  });

  test('gives up when the services never resolve', () async {
    await start();
    bluez.iphone.interfaces['org.bluez.Device1']?['ServicesResolved'] =
        const DBusBoolean(false);

    await expectLater(
      transport.connect(FakeBluez.iphonePath),
      throwsA(
        isA<GattException>().having(
          (error) => error.failure,
          'failure',
          GattFailure.timeout,
        ),
      ),
    );
  });

  test(
    'reports a service whose characteristics are missing as absent',
    () async {
      await start();
      bluez.characteristics['eu']?.interfaces.clear();

      final services = await transport.connect(FakeBluez.iphonePath);

      expect(services.hasAncs, isTrue);
      expect(services.hasAms, isFalse);
      await expectLater(
        transport.write(.entityUpdate, Uint8List(1)),
        throwsA(
          isA<GattException>().having(
            (error) => error.failure,
            'failure',
            GattFailure.missing,
          ),
        ),
      );
    },
  );

  test('writes with a response, reads, and turns notify on and off', () async {
    await start();
    await transport.connect(FakeBluez.iphonePath);
    final written = <List<int>>[];
    final control = bluez.characteristics['cp'];
    final attribute = bluez.characteristics['ea'];
    control?.onCall = (call) {
      written.add(call.values.first.asByteArray().toList());
      expect(
        call.values[1].asStringVariantDict()['type'],
        const DBusString('request'),
      );
      return DBusMethodSuccessResponse();
    };
    attribute?.onCall = (call) => DBusMethodSuccessResponse([
      DBusArray.byte(const [7, 8, 9]),
    ]);

    await transport.write(
      .controlPoint,
      Uint8List.fromList([2, 1, 0, 0, 0, 1]),
    );
    final value = await transport.read(.entityAttribute);
    await transport.setNotify(.dataSource, enabled: true);
    await transport.setNotify(.dataSource, enabled: false);

    expect(written, [
      [2, 1, 0, 0, 0, 1],
    ]);
    expect(value, [7, 8, 9]);
    expect(bluez.characteristics['ds']?.calls, ['StartNotify', 'StopNotify']);
  });

  test('passes on notified values of the Apple characteristics', () async {
    await start();
    await transport.connect(FakeBluez.iphonePath);
    final values = <GattValue>[];
    transport.values.listen(values.add);
    await settle();

    await bluez.characteristics['ns']?.change(
      'org.bluez.GattCharacteristic1',
      'Value',
      DBusArray.byte(const [0, 0, 4, 1, 9, 0, 0, 0]),
    );
    await bluez.characteristics['ns']?.change(
      'org.bluez.GattCharacteristic1',
      'Notifying',
      const DBusBoolean(true),
    );
    await settle();

    expect(
      values.single.characteristic,
      AppleCharacteristic.notificationSource,
    );
    expect(values.single.bytes, [0, 0, 4, 1, 9, 0, 0, 0]);
  });

  test('reports the drop when the iPhone goes out of reach', () async {
    await start();
    await transport.connect(FakeBluez.iphonePath);
    final drops = <String>[];
    transport.disconnects.listen(drops.add);
    await settle();

    await bluez.iphone.change(
      'org.bluez.Device1',
      'Connected',
      const DBusBoolean(false),
    );
    await settle();

    expect(drops, [FakeBluez.iphonePath]);
    await expectLater(
      transport.write(.controlPoint, Uint8List(1)),
      throwsA(
        isA<GattException>().having(
          (error) => error.failure,
          'failure',
          GattFailure.notConnected,
        ),
      ),
    );
  });

  test('invites the iPhone with an advertisement that asks for ANCS', () async {
    await start();
    final registered = <DBusObjectPath>[];
    bluez.adapter.onCall = (call) {
      registered.add(call.values.first.asObjectPath());
      return DBusMethodSuccessResponse();
    };

    await transport.setInviting(inviting: true);
    await transport.setInviting(inviting: true);
    final probe = bluez.connect();
    addTearDown(probe.close);
    final names = await probe.listNames();
    final advertiser = names.where((name) => name.startsWith(':')).toList();
    final properties = <String, DBusValue>{};
    for (final name in advertiser) {
      try {
        properties.addAll(
          await DBusRemoteObject(
            probe,
            name: name,
            path: registered.first,
          ).getAllProperties('org.bluez.LEAdvertisement1'),
        );
      } on DBusMethodResponseException {
        continue;
      }
    }

    await transport.setInviting(inviting: false);

    expect(bluez.adapter.calls, [
      'RegisterAdvertisement',
      'UnregisterAdvertisement',
    ]);
    expect(properties['Type'], const DBusString('peripheral'));
    expect(properties['SolicitUUIDs']?.asStringArray(), [
      '7905f431-b5ce-4e99-a40f-4b1e122d00d0',
    ]);
  });

  test('opens the first Bluetooth settings app that exists', () async {
    await start();

    await transport.openBluetoothSettings();

    expect(started, [
      'gnome-control-center',
      'systemsettings',
      'blueman-manager',
    ]);
  });

  test('maps BlueZ errors to failures', () {
    expect(
      BluezTransport.failureOf('org.bluez.Error.NotAuthorized', '').failure,
      GattFailure.notBonded,
    );
    expect(
      BluezTransport.failureOf('org.bluez.Error.NotConnected', '').failure,
      GattFailure.notConnected,
    );
    final att = BluezTransport.failureOf(
      'org.bluez.Error.Failed',
      'Operation failed with ATT error: 0xa2',
    );
    expect(att.failure, GattFailure.att);
    expect(att.attError, 0xA2);
    expect(
      BluezTransport.failureOf('org.bluez.Error.Failed', 'No luck').failure,
      GattFailure.failed,
    );
  });
}
