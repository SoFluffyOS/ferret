import 'dart:typed_data';

import 'package:ferret_iphone/src/transport/apple_characteristic.dart';

/// Whether this computer can use Bluetooth LE right now.
enum BluetoothStatus {
  ready,
  off,

  /// The person said no to Bluetooth for this app.
  unauthorized,

  /// No Bluetooth LE adapter, or a platform that can't do this.
  unsupported,

  /// The app was built without what the system needs to allow Bluetooth.
  notConfigured,
}

/// A device the system already knows, which may be an iPhone.
class BondedDevice {
  const BondedDevice({
    required this.id,
    required this.name,
    this.connected = false,
  });

  /// The system's own id for the device; opaque, and only valid on this
  /// computer.
  final String id;
  final String name;
  final bool connected;
}

/// Which Apple services the connected device offers. An iPhone only shows
/// them to a device it is bonded with.
class AppleServices {
  const AppleServices({this.hasAncs = false, this.hasAms = false});

  final bool hasAncs;
  final bool hasAms;

  bool get isEmpty => !hasAncs && !hasAms;
}

/// A notification from a characteristic.
class GattValue {
  const GattValue(this.characteristic, this.bytes);

  final AppleCharacteristic characteristic;
  final Uint8List bytes;
}

/// Why a GATT operation failed.
enum GattFailure {
  /// There is no link to the iPhone (out of reach, Bluetooth off).
  notConnected,

  /// The iPhone refused because the link isn't bonded and encrypted.
  notBonded,

  /// The iPhone doesn't offer that characteristic.
  missing,

  /// The iPhone answered with an ATT error, in [GattException.attError].
  att,

  /// It took too long.
  timeout,

  failed,
}

class GattException implements Exception {
  const GattException(this.failure, {this.attError});

  final GattFailure failure;

  /// The ATT error code, such as `0xA2` (invalid parameter) from ANCS.
  final int? attError;

  @override
  String toString() => switch (attError) {
    final code? =>
      'GattException(${failure.name}, 0x${code.toRadixString(16)})',
    null => 'GattException(${failure.name})',
  };
}
