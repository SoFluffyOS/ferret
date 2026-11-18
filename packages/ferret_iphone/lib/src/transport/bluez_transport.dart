import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dbus/dbus.dart';
import 'package:ferret_iphone/src/transport/apple_characteristic.dart';
import 'package:ferret_iphone/src/transport/apple_transport.dart';
import 'package:ferret_iphone/src/transport/apple_transport_models.dart';
import 'package:ferret_iphone/src/transport/bluez_advertisement.dart';

/// Starts a command, such as the desktop's Bluetooth settings.
typedef StartSettings = Future<Process> Function(
  String executable,
  List<String> arguments,
);

typedef _Objects = Map<DBusObjectPath, Map<String, Map<String, DBusValue>>>;

/// The iPhone link on Linux: BlueZ over the system D-Bus, in Dart. Device ids
/// are BlueZ object paths.
///
/// An iPhone rarely accepts a Bluetooth LE connection a computer starts, so
/// this can also invite it: an advertisement that asks for ANCS makes the
/// computer show up in the iPhone's Bluetooth list, and makes a bonded
/// iPhone come back on its own.
class BluezTransport implements AppleTransport {
  BluezTransport({
    DBusClient Function()? connect,
    StartSettings? startSettings,
    this.resolveTimeout = const Duration(seconds: 15),
  }) : _connect = connect ?? DBusClient.system,
       _startSettings = startSettings ?? Process.start;

  static const _bluez = 'org.bluez';
  static const _adapterInterface = 'org.bluez.Adapter1';
  static const _deviceInterface = 'org.bluez.Device1';
  static const _characteristicInterface = 'org.bluez.GattCharacteristic1';
  static const _advertisingInterface = 'org.bluez.LEAdvertisingManager1';
  static const _propertiesInterface = 'org.freedesktop.DBus.Properties';

  /// Settings apps to try, most common desktops first.
  static const settingsCommands = [
    ('gnome-control-center', ['bluetooth']),
    ('systemsettings', ['kcm_bluetooth']),
    ('blueman-manager', <String>[]),
  ];

  /// How long to wait for BlueZ to list the iPhone's services after the link
  /// comes up.
  final Duration resolveTimeout;

  final DBusClient Function() _connect;
  final StartSettings _startSettings;
  final StreamController<GattValue> _values = .broadcast();
  final StreamController<String> _disconnects = .broadcast();
  final Map<AppleCharacteristic, DBusObjectPath> _characteristics = {};

  DBusClient? _client;
  StreamSubscription<DBusSignal>? _signals;
  DBusObjectPath? _device;
  BluezAdvertisement? _advertisement;
  DBusObjectPath? _advertisingAdapter;

  @override
  Stream<GattValue> get values => _values.stream;

  @override
  Stream<String> get disconnects => _disconnects.stream;

  @override
  bool get canInvite => true;

  @override
  Future<BluetoothStatus> status() async {
    final _Objects objects;
    try {
      objects = await _objects();
    } on Object {
      return .unsupported;
    }

    final adapters = [
      for (final interfaces in objects.values) ?interfaces[_adapterInterface],
    ];
    if (adapters.isEmpty) {
      return .unsupported;
    }

    final powered = adapters.any((adapter) => _flag(adapter, 'Powered'));
    return switch (powered) {
      true => .ready,
      false => .off,
    };
  }

  @override
  Future<List<BondedDevice>> devices() async {
    final objects = await _guard(_objects);

    return [
      for (final MapEntry(key: path, value: interfaces) in objects.entries)
        if (interfaces[_deviceInterface] case final device?)
          if (_flag(device, 'Paired'))
            BondedDevice(
              id: path.value,
              name: _text(device, 'Alias') ?? _text(device, 'Name') ?? '',
              connected: _flag(device, 'Connected'),
            ),
    ];
  }

  @override
  Future<AppleServices> connect(String deviceId) async {
    await _dropLink();
    final path = DBusObjectPath(deviceId);
    final client = _ensureClient();
    final device = DBusRemoteObject(client, name: _bluez, path: path);

    final properties = await _guard(
      () => device.getAllProperties(_deviceInterface),
    );
    if (!_flag(properties, 'Connected')) {
      await _guard(
        () => device.callMethod(
          _deviceInterface,
          'Connect',
          const [],
          replySignature: DBusSignature(''),
        ),
      );
    }

    await _waitForServices(device);
    _device = path;
    _characteristics
      ..clear()
      ..addAll(_findCharacteristics(await _guard(_objects), path));
    _signals = DBusSignalStream(
      client,
      sender: _bluez,
      interface: _propertiesInterface,
      name: 'PropertiesChanged',
      pathNamespace: path,
    ).listen(_onPropertiesChanged);

    return AppleServices(
      hasAncs: _hasAll(.ancs),
      hasAms: _hasAll(.ams),
    );
  }

  /// Forgets the link without closing it: the Bluetooth connection to a
  /// bonded iPhone belongs to the system, and the iPhone would only make it
  /// again.
  @override
  Future<void> disconnect() async {
    for (final characteristic in AppleCharacteristic.values) {
      try {
        await _stopNotify(characteristic);
      } on Object {
        // The link may already be gone; there is nothing left to turn off.
      }
    }

    await _dropLink();
  }

  @override
  Future<void> write(AppleCharacteristic characteristic, Uint8List value) =>
      _guard(
        () => _remote(characteristic).callMethod(
          _characteristicInterface,
          'WriteValue',
          [
            DBusArray.byte(value),
            DBusDict.stringVariant({'type': const DBusString('request')}),
          ],
          replySignature: DBusSignature(''),
        ),
      );

  @override
  Future<Uint8List> read(AppleCharacteristic characteristic) async {
    final response = await _guard(
      () => _remote(characteristic).callMethod(
        _characteristicInterface,
        'ReadValue',
        [DBusDict.stringVariant(const {})],
        replySignature: DBusSignature('ay'),
      ),
    );

    return Uint8List.fromList(response.values.first.asByteArray().toList());
  }

  @override
  Future<void> setNotify(
    AppleCharacteristic characteristic, {
    required bool enabled,
  }) {
    if (!enabled) {
      return _guard(() => _stopNotify(characteristic));
    }

    return _guard(
      () => _remote(characteristic).callMethod(
        _characteristicInterface,
        'StartNotify',
        const [],
        replySignature: DBusSignature(''),
      ),
    );
  }

  @override
  Future<void> setInviting({required bool inviting}) async {
    if (!inviting) {
      await _stopInviting();
      return;
    }

    if (_advertisement != null) {
      return;
    }

    final objects = await _guard(_objects);
    final adapter = _advertisingAdapterIn(objects);
    if (adapter == null) {
      throw const GattException(.failed);
    }

    final client = _ensureClient();
    final advertisement = BluezAdvertisement();
    await client.registerObject(advertisement);
    try {
      await _guard(
        () => client.callMethod(
          destination: _bluez,
          path: adapter,
          interface: _advertisingInterface,
          name: 'RegisterAdvertisement',
          values: [advertisement.path, DBusDict.stringVariant(const {})],
          replySignature: DBusSignature(''),
        ),
      );
    } on Object {
      await client.unregisterObject(advertisement);
      rethrow;
    }

    _advertisement = advertisement;
    _advertisingAdapter = adapter;
  }

  @override
  Future<void> openBluetoothSettings() async {
    for (final (executable, arguments) in settingsCommands) {
      try {
        await _startSettings(executable, arguments);
        return;
      } on Object {
        continue;
      }
    }

    throw const GattException(.failed);
  }

  @override
  Future<void> dispose() async {
    try {
      await _stopInviting();
    } on Object {
      // BlueZ drops the advertisement itself when this client goes away.
    }

    await _dropLink();
    await _values.close();
    await _disconnects.close();
    await _client?.close();
    _client = null;
  }

  DBusClient _ensureClient() => _client ??= _connect();

  Future<_Objects> _objects() => DBusRemoteObjectManager(
    _ensureClient(),
    name: _bluez,
    path: DBusObjectPath('/'),
  ).getManagedObjects();

  DBusRemoteObject _remote(AppleCharacteristic characteristic) {
    final path = _characteristics[characteristic];
    if (path == null) {
      final failure = switch (_device) {
        null => GattFailure.notConnected,
        _ => GattFailure.missing,
      };
      throw GattException(failure);
    }

    return DBusRemoteObject(_ensureClient(), name: _bluez, path: path);
  }

  Future<void> _stopNotify(AppleCharacteristic characteristic) async {
    if (!_characteristics.containsKey(characteristic)) {
      return;
    }

    await _remote(characteristic).callMethod(
      _characteristicInterface,
      'StopNotify',
      const [],
      replySignature: DBusSignature(''),
    );
  }

  Future<void> _dropLink() async {
    await _signals?.cancel();
    _signals = null;
    _device = null;
    _characteristics.clear();
  }

  Future<void> _stopInviting() async {
    final advertisement = _advertisement;
    final adapter = _advertisingAdapter;
    final client = _client;
    _advertisement = null;
    _advertisingAdapter = null;
    if (advertisement == null || adapter == null || client == null) {
      return;
    }

    try {
      await client.callMethod(
        destination: _bluez,
        path: adapter,
        interface: _advertisingInterface,
        name: 'UnregisterAdvertisement',
        values: [advertisement.path],
        replySignature: DBusSignature(''),
      );
    } finally {
      await client.unregisterObject(advertisement);
    }
  }

  /// BlueZ lists a device's characteristics a moment after the link comes
  /// up; `ServicesResolved` says when.
  Future<void> _waitForServices(DBusRemoteObject device) async {
    final deadline = DateTime.now().add(resolveTimeout);
    while (true) {
      final resolved = await _guard(
        () => device.getProperty(_deviceInterface, 'ServicesResolved'),
      );
      if (resolved case DBusBoolean(value: true)) {
        return;
      }

      if (DateTime.now().isAfter(deadline)) {
        throw const GattException(.timeout);
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Map<AppleCharacteristic, DBusObjectPath> _findCharacteristics(
    _Objects objects,
    DBusObjectPath device,
  ) {
    final prefix = '${device.value}/';
    final found = <AppleCharacteristic, DBusObjectPath>{};
    for (final MapEntry(key: path, value: interfaces) in objects.entries) {
      final properties = interfaces[_characteristicInterface];
      if (properties == null || !path.value.startsWith(prefix)) {
        continue;
      }

      final known = AppleCharacteristic.fromUuid(
        _text(properties, 'UUID') ?? '',
      );
      if (known != null) {
        found[known] = path;
      }
    }

    return found;
  }

  bool _hasAll(AppleService service) => AppleCharacteristic.values
      .where((characteristic) => characteristic.service == service)
      .every(_characteristics.containsKey);

  DBusObjectPath? _advertisingAdapterIn(_Objects objects) {
    for (final MapEntry(key: path, value: interfaces) in objects.entries) {
      final adapter = interfaces[_adapterInterface];
      if (adapter == null || !interfaces.containsKey(_advertisingInterface)) {
        continue;
      }

      if (_flag(adapter, 'Powered')) {
        return path;
      }
    }

    return null;
  }

  void _onPropertiesChanged(DBusSignal signal) {
    if (signal.values.length < 2 || _values.isClosed) {
      return;
    }

    final [interface, changed, ...] = signal.values;
    if (interface is! DBusString || changed is! DBusDict) {
      return;
    }

    final properties = {
      for (final MapEntry(:key, :value) in changed.children.entries)
        if (key is DBusString && value is DBusVariant) key.value: value.value,
    };
    if (interface.value == _deviceInterface && signal.path == _device) {
      _onDeviceChanged(signal.path, properties);
      return;
    }

    if (interface.value != _characteristicInterface) {
      return;
    }

    final value = properties['Value'];
    if (value is! DBusArray || value.childSignature != DBusSignature('y')) {
      return;
    }

    for (final MapEntry(key: characteristic, value: path)
        in _characteristics.entries) {
      if (path == signal.path) {
        _values.add(
          GattValue(
            characteristic,
            Uint8List.fromList(value.asByteArray().toList()),
          ),
        );
        return;
      }
    }
  }

  void _onDeviceChanged(DBusObjectPath path, Map<String, DBusValue> changed) {
    if (changed['Connected'] case DBusBoolean(value: false)) {
      unawaited(_dropLink());
      _disconnects.add(path.value);
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on GattException {
      rethrow;
    } on DBusMethodResponseException catch (error) {
      throw failureOf(error.errorName, _messageOf(error));
    } on Object {
      throw const GattException(.failed);
    }
  }

  String _messageOf(DBusMethodResponseException error) =>
      switch (error.response.values) {
        [DBusString(:final value), ...] => value,
        _ => '',
      };

  /// BlueZ's D-Bus errors as a [GattException]. An ATT error from the
  /// iPhone arrives as `org.bluez.Error.Failed` with the code in the text.
  static GattException failureOf(String errorName, String message) {
    final attError = RegExp(
      r'0x([0-9a-fA-F]{2})\b',
    ).firstMatch(message)?.group(1);

    return switch (errorName) {
      'org.bluez.Error.NotAuthorized' ||
      'org.bluez.Error.NotPermitted' ||
      'org.bluez.Error.AuthenticationFailed' ||
      'org.bluez.Error.AuthenticationCanceled' ||
      'org.bluez.Error.AuthenticationRejected' ||
      'org.bluez.Error.AuthenticationTimeout' => const GattException(
        .notBonded,
      ),
      'org.bluez.Error.NotConnected' ||
      'org.bluez.Error.NotReady' ||
      'org.bluez.Error.NotAvailable' ||
      'org.bluez.Error.ConnectionAttemptFailed' ||
      'org.bluez.Error.DoesNotExist' ||
      'org.freedesktop.DBus.Error.UnknownObject' ||
      'org.freedesktop.DBus.Error.ServiceUnknown' => const GattException(
        .notConnected,
      ),
      'org.bluez.Error.Failed' when attError != null => GattException(
        .att,
        attError: int.parse(attError, radix: 16),
      ),
      _ => const GattException(.failed),
    };
  }

  static bool _flag(Map<String, DBusValue> properties, String name) =>
      switch (properties[name]) {
        DBusBoolean(:final value) => value,
        _ => false,
      };

  static String? _text(Map<String, DBusValue> properties, String name) =>
      switch (properties[name]) {
        DBusString(:final value) => value,
        _ => null,
      };
}
