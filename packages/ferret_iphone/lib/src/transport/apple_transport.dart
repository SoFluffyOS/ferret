import 'dart:io';
import 'dart:typed_data';

import 'package:ferret_iphone/src/transport/apple_characteristic.dart';
import 'package:ferret_iphone/src/transport/apple_transport_models.dart';
import 'package:ferret_iphone/src/transport/bluez_transport.dart';
import 'package:ferret_iphone/src/transport/pigeon_transport.dart';
import 'package:ferret_iphone/src/transport/unsupported_transport.dart';

/// A Bluetooth LE GATT client for one iPhone's Apple services. Everything
/// above it (ANCS, AMS) is plain Dart; operations throw [GattException].
abstract interface class AppleTransport {
  /// The implementation for the platform the app runs on: BlueZ on Linux,
  /// the native plugin on Windows and macOS, nothing on phones.
  factory AppleTransport.current() {
    if (Platform.isLinux) {
      return BluezTransport();
    }

    if (Platform.isWindows || Platform.isMacOS) {
      return PigeonTransport();
    }

    return const UnsupportedTransport();
  }

  /// May ask the person for Bluetooth access the first time (macOS).
  Future<BluetoothStatus> status();

  /// Devices that could be the iPhone: bonded with this computer (Windows,
  /// Linux), or connected to it and offering an Apple service (macOS).
  Future<List<BondedDevice>> devices();

  /// Connects to [deviceId] and looks for the Apple services. Replaces any
  /// earlier link.
  Future<AppleServices> connect(String deviceId);

  Future<void> disconnect();

  Future<void> write(AppleCharacteristic characteristic, Uint8List value);

  Future<Uint8List> read(AppleCharacteristic characteristic);

  Future<void> setNotify(
    AppleCharacteristic characteristic, {
    required bool enabled,
  });

  /// Notifications from every characteristic that has notify on.
  Stream<GattValue> get values;

  /// Fires with the device id when the link drops.
  Stream<String> get disconnects;

  /// Whether this computer can show itself to the iPhone as something that
  /// wants its notifications, so it appears in the iPhone's Bluetooth list
  /// and the iPhone reconnects on its own (Linux).
  bool get canInvite;

  /// Starts or stops showing this computer to the iPhone. Does nothing when
  /// [canInvite] is false.
  Future<void> setInviting({required bool inviting});

  /// Opens the system's Bluetooth settings, where people pair the iPhone.
  Future<void> openBluetoothSettings();

  Future<void> dispose();
}
