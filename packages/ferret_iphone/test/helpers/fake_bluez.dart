import 'dart:io';

import 'package:dbus/dbus.dart';

/// One exported BlueZ object: its interfaces with their properties, and what
/// its methods do.
class FakeBluezObject extends DBusObject {
  FakeBluezObject(String path, this.interfaces) : super(DBusObjectPath(path));

  final Map<String, Map<String, DBusValue>> interfaces;
  final List<String> calls = [];

  /// Answers a method by name; without one, methods succeed with nothing.
  DBusMethodResponse Function(DBusMethodCall call)? onCall;

  @override
  Map<String, Map<String, DBusValue>> get interfacesAndProperties => interfaces;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    calls.add(methodCall.name);
    return onCall?.call(methodCall) ?? DBusMethodSuccessResponse();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    final value = interfaces[interface]?[name];
    if (value == null) {
      return DBusMethodErrorResponse.unknownProperty();
    }

    return DBusGetPropertyResponse(value);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async =>
      DBusGetAllPropertiesResponse(interfaces[interface] ?? const {});

  /// Changes [name] and tells listeners, as BlueZ does.
  Future<void> change(String interface, String name, DBusValue value) async {
    interfaces[interface]?[name] = value;
    await emitPropertiesChanged(interface, changedProperties: {name: value});
  }
}

/// A private bus with a service named `org.bluez` on it: an adapter, one
/// paired iPhone with the ANCS and AMS characteristics, and one other device.
class FakeBluez {
  FakeBluez._(this._server, this._service, this.address);

  static const adapterPath = '/org/bluez/hci0';
  static const iphonePath = '/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF';
  static const strangerPath = '/org/bluez/hci0/dev_11_22_33_44_55_66';

  static const uuids = {
    'ns': '9fbf120d-6301-42d9-8c58-25e699a21dbd',
    'cp': '69d1d8f3-45e1-49a8-9821-9bbdfdaad9d9',
    'ds': '22eac6e9-24d6-4bb5-be44-b36ace7c7bfb',
    'rc': '9b3c81d8-57b1-4a8a-b8df-0e56f7ca51c2',
    'eu': '2f7cabce-808d-411f-9a0c-bb92ba96c102',
    'ea': 'c6b2f38c-23ab-46d8-a6ab-a3a870bbd5d7',
  };

  final DBusServer _server;
  final DBusClient _service;
  final DBusAddress address;
  late final Directory _directory;

  late final FakeBluezObject adapter;
  late final FakeBluezObject iphone;
  final Map<String, FakeBluezObject> characteristics = {};

  static Future<FakeBluez> start({bool connected = true}) async {
    final directory = await Directory.systemTemp.createTemp('fake-bluez');
    final server = DBusServer();
    final address = await server.listenAddress(
      DBusAddress.unix(dir: directory),
    );
    final service = clientFor(address);
    await service.requestName('org.bluez');
    final bluez = FakeBluez._(server, service, address).._directory = directory;
    await bluez._export(connected: connected);
    return bluez;
  }

  /// A client on the private bus, for the transport under test.
  DBusClient connect() => clientFor(address);

  /// The private bus runs on macOS too, where the client can't look up its
  /// own user id, so the test supplies one.
  static DBusClient clientFor(DBusAddress address) => DBusClient(
    address,
    authClient: DBusAuthClient(uid: '1000', requestUnixFd: false),
  );

  Future<void> stop() async {
    await _service.close();
    await _server.close();
    await _directory.delete(recursive: true);
  }

  Future<void> _export({required bool connected}) async {
    await _service.registerObject(
      DBusObject(DBusObjectPath('/'), isObjectManager: true),
    );
    adapter = FakeBluezObject(adapterPath, {
      'org.bluez.Adapter1': {'Powered': const DBusBoolean(true)},
      'org.bluez.LEAdvertisingManager1': {},
    });
    iphone = FakeBluezObject(iphonePath, {
      'org.bluez.Device1': {
        'Alias': const DBusString('Simon’s iPhone'),
        'Paired': const DBusBoolean(true),
        'Connected': DBusBoolean(connected),
        'ServicesResolved': DBusBoolean(connected),
      },
    });
    final stranger = FakeBluezObject(strangerPath, {
      'org.bluez.Device1': {
        'Name': const DBusString('Headphones'),
        'Paired': const DBusBoolean(false),
        'Connected': const DBusBoolean(false),
      },
    });
    for (final object in [adapter, iphone, stranger]) {
      await _service.registerObject(object);
    }

    var index = 1;
    for (final MapEntry(key: name, value: uuid) in uuids.entries) {
      final characteristic = FakeBluezObject(
        '$iphonePath/service0010/char00${index++}0',
        {
          'org.bluez.GattCharacteristic1': {
            'UUID': DBusString(uuid),
            'Value': DBusArray.byte(const []),
          },
        },
      );
      characteristics[name] = characteristic;
      await _service.registerObject(characteristic);
    }
  }
}
