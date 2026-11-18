import 'dart:async';

import 'package:ferret_iphone/src/messages.g.dart';
import 'package:ferret_iphone/src/transport/apple_characteristic.dart';
import 'package:ferret_iphone/src/transport/apple_transport.dart';
import 'package:ferret_iphone/src/transport/apple_transport_models.dart';
import 'package:flutter/services.dart';

/// The iPhone link through the native plugin: C++/WinRT on Windows,
/// CoreBluetooth on macOS.
class PigeonTransport implements AppleTransport, AppleGattFlutterApi {
  PigeonTransport({AppleGattHostApi? api}) : _api = api ?? AppleGattHostApi() {
    AppleGattFlutterApi.setUp(this);
  }

  final AppleGattHostApi _api;
  final StreamController<GattValue> _values = .broadcast();
  final StreamController<String> _disconnects = .broadcast();

  @override
  Stream<GattValue> get values => _values.stream;

  @override
  Stream<String> get disconnects => _disconnects.stream;

  @override
  bool get canInvite => false;

  @override
  Future<BluetoothStatus> status() async {
    final status = await _guard(_api.status);
    return switch (status) {
      .ready => .ready,
      .off => .off,
      .unauthorized => .unauthorized,
      .unsupported => .unsupported,
      .notConfigured => .notConfigured,
    };
  }

  @override
  Future<List<BondedDevice>> devices() async {
    final devices = await _guard(_api.devices);
    return [
      for (final device in devices)
        BondedDevice(
          id: device.id,
          name: device.name,
          connected: device.connected,
        ),
    ];
  }

  @override
  Future<AppleServices> connect(String deviceId) async {
    final services = await _guard(() => _api.connect(deviceId));
    return AppleServices(hasAncs: services.hasAncs, hasAms: services.hasAms);
  }

  @override
  Future<void> disconnect() => _guard(_api.disconnect);

  @override
  Future<void> write(AppleCharacteristic characteristic, Uint8List value) =>
      _guard(() => _api.write(characteristic.uuid, value));

  @override
  Future<Uint8List> read(AppleCharacteristic characteristic) =>
      _guard(() => _api.read(characteristic.uuid));

  @override
  Future<void> setNotify(
    AppleCharacteristic characteristic, {
    required bool enabled,
  }) => _guard(() => _api.setNotify(characteristic.uuid, enabled));

  @override
  Future<void> setInviting({required bool inviting}) async {}

  @override
  Future<void> openBluetoothSettings() => _api.openBluetoothSettings();

  @override
  Future<void> dispose() async {
    AppleGattFlutterApi.setUp(null);
    await _values.close();
    await _disconnects.close();
  }

  @override
  void onValue(String characteristic, Uint8List value) {
    final known = AppleCharacteristic.fromUuid(characteristic);
    if (known == null || _values.isClosed) {
      return;
    }

    _values.add(GattValue(known, value));
  }

  @override
  void onDisconnected(String deviceId) {
    if (!_disconnects.isClosed) {
      _disconnects.add(deviceId);
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (error) {
      throw failureOf(error);
    }
  }

  /// The plugin's error codes as a [GattException].
  static GattException failureOf(PlatformException error) =>
      switch (error.code) {
        'not_connected' => const GattException(.notConnected),
        'not_bonded' => const GattException(.notBonded),
        'missing' => const GattException(.missing),
        'att' => GattException(
          .att,
          attError: switch (error.details) {
            final int code => code,
            _ => null,
          },
        ),
        _ => const GattException(.failed),
      };
}
