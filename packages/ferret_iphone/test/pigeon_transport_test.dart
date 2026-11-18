import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:ferret_iphone/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps status, devices and services', () async {
    final api = _FakeHostApi();
    final transport = PigeonTransport(api: api);

    final status = await transport.status();
    final devices = await transport.devices();
    final services = await transport.connect('id-1');

    expect(status, BluetoothStatus.off);
    expect(devices.single.id, 'id-1');
    expect(devices.single.name, 'iPhone');
    expect(devices.single.connected, isTrue);
    expect(services.hasAncs, isTrue);
    expect(services.hasAms, isFalse);
    expect(api.connected, 'id-1');
  });

  test('names characteristics by their upper-case UUID', () async {
    final api = _FakeHostApi();
    final transport = PigeonTransport(api: api);

    await transport.write(
      .controlPoint,
      Uint8List.fromList([2, 1, 0, 0, 0, 1]),
    );
    await transport.setNotify(.dataSource, enabled: true);
    final value = await transport.read(.entityAttribute);

    expect(api.calls, [
      'write 69D1D8F3-45E1-49A8-9821-9BBDFDAAD9D9 [2, 1, 0, 0, 0, 1]',
      'notify 22EAC6E9-24D6-4BB5-BE44-B36ACE7C7BFB true',
      'read C6B2F38C-23AB-46D8-A6AB-A3A870BBD5D7',
    ]);
    expect(value, [1, 2, 3]);
  });

  test('passes on native values and drops, skipping unknown UUIDs', () async {
    final transport = PigeonTransport(api: _FakeHostApi());
    final values = <GattValue>[];
    final drops = <String>[];
    transport.values.listen(values.add);
    transport.disconnects.listen(drops.add);

    transport
      ..onValue(
        '9fbf120d-6301-42d9-8c58-25e699a21dbd',
        Uint8List.fromList([0, 0, 0, 1, 1, 0, 0, 0]),
      )
      ..onValue('0000180F-0000-1000-8000-00805F9B34FB', Uint8List(1))
      ..onDisconnected('id-1');
    await Future<void>.delayed(Duration.zero);

    expect(
      values.single.characteristic,
      AppleCharacteristic.notificationSource,
    );
    expect(drops, ['id-1']);
  });

  test('turns the plugin error codes into failures', () {
    GattException of(String code, [Object? details]) =>
        PigeonTransport.failureOf(
          PlatformException(code: code, details: details),
        );

    expect(of('not_connected').failure, GattFailure.notConnected);
    expect(of('not_bonded').failure, GattFailure.notBonded);
    expect(of('missing').failure, GattFailure.missing);
    expect(of('att', 0xA2).failure, GattFailure.att);
    expect(of('att', 0xA2).attError, 0xA2);
    expect(of('anything').failure, GattFailure.failed);
  });

  test('a failing call throws a GattException', () async {
    final api = _FakeHostApi()..failure = PlatformException(code: 'not_bonded');
    final transport = PigeonTransport(api: api);

    await expectLater(
      transport.setNotify(.notificationSource, enabled: true),
      throwsA(
        isA<GattException>().having(
          (error) => error.failure,
          'failure',
          GattFailure.notBonded,
        ),
      ),
    );
  });
}

class _FakeHostApi implements AppleGattHostApi {
  final List<String> calls = [];
  String? connected;
  PlatformException? failure;

  @override
  Future<PlatformBluetoothStatus> status() async => .off;

  @override
  Future<List<PlatformBondedDevice>> devices() async => [
    PlatformBondedDevice(id: 'id-1', name: 'iPhone', connected: true),
  ];

  @override
  Future<PlatformAppleServices> connect(String deviceId) async {
    connected = deviceId;
    return PlatformAppleServices(hasAncs: true, hasAms: false);
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> write(String characteristic, Uint8List value) async {
    calls.add('write $characteristic $value');
  }

  @override
  Future<Uint8List> read(String characteristic) async {
    calls.add('read $characteristic');
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> setNotify(String characteristic, bool enabled) async {
    if (failure case final failure?) {
      throw failure;
    }

    calls.add('notify $characteristic $enabled');
  }

  @override
  Future<void> openBluetoothSettings() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
