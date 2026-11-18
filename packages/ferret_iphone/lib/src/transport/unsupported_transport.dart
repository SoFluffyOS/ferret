import 'dart:typed_data';

import 'package:ferret_iphone/src/transport/apple_characteristic.dart';
import 'package:ferret_iphone/src/transport/apple_transport.dart';
import 'package:ferret_iphone/src/transport/apple_transport_models.dart';

/// For platforms that can't be a Bluetooth client of an iPhone (Android and
/// iOS, where Ferret phones talk Ferret instead).
class UnsupportedTransport implements AppleTransport {
  const UnsupportedTransport();

  @override
  Future<BluetoothStatus> status() async => .unsupported;

  @override
  Future<List<BondedDevice>> devices() async => const [];

  @override
  Future<AppleServices> connect(String deviceId) async =>
      throw const GattException(.notConnected);

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> write(AppleCharacteristic characteristic, Uint8List value) =>
      throw const GattException(.notConnected);

  @override
  Future<Uint8List> read(AppleCharacteristic characteristic) =>
      throw const GattException(.notConnected);

  @override
  Future<void> setNotify(
    AppleCharacteristic characteristic, {
    required bool enabled,
  }) => throw const GattException(.notConnected);

  @override
  Stream<GattValue> get values => const Stream.empty();

  @override
  Stream<String> get disconnects => const Stream.empty();

  @override
  bool get canInvite => false;

  @override
  Future<void> setInviting({required bool inviting}) async {}

  @override
  Future<void> openBluetoothSettings() async {}

  @override
  Future<void> dispose() async {}
}
