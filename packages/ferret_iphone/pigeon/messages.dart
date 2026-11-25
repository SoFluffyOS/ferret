import 'package:pigeon/pigeon.dart';

// Regenerate with `dart run pigeon --input pigeon/messages.dart` from the
// package folder. Linux is Dart only (lib/src/transport/bluez_transport.dart).
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_iphone',
    dartOut: 'lib/src/messages.g.dart',
    cppHeaderOut: 'windows/messages.g.h',
    cppSourceOut: 'windows/messages.g.cpp',
    cppOptions: CppOptions(namespace: 'ferret_iphone'),
    swiftOut: 'macos/ferret_iphone/Sources/ferret_iphone/Messages.g.swift',
  ),
)
/// Whether this computer can use Bluetooth LE right now.
enum PlatformBluetoothStatus {
  ready,
  off,

  /// The person said no to Bluetooth for this app.
  unauthorized,

  /// No Bluetooth LE adapter.
  unsupported,

  /// The app was built without what the system needs to allow Bluetooth
  /// (the usage string or the sandbox entitlement on macOS).
  notConfigured,
}

/// A device the system already knows, which may be an iPhone.
class PlatformBondedDevice {
  PlatformBondedDevice({
    required this.id,
    required this.name,
    required this.connected,
  });

  /// The system's own id for the device; opaque.
  String id;
  String name;
  bool connected;
}

/// Which Apple services the connected device offers.
class PlatformAppleServices {
  PlatformAppleServices({required this.hasAncs, required this.hasAms});

  bool hasAncs;
  bool hasAms;
}

/// A GATT client for one iPhone. Characteristics are named by their UUID in
/// upper case. Failures are errors with the code `not_connected`,
/// `not_bonded`, `missing`, `att` (details: the ATT error code) or `failed`.
@HostApi()
abstract class AppleGattHostApi {
  @async
  PlatformBluetoothStatus status();

  /// Devices bonded with this computer (Windows), or connected to it and
  /// offering an Apple service (macOS).
  @async
  List<PlatformBondedDevice> devices();

  /// Connects and looks for the Apple services. Replaces any earlier link.
  @async
  PlatformAppleServices connect(String deviceId);

  @async
  void disconnect();

  @async
  void write(String characteristic, Uint8List value);

  @async
  Uint8List read(String characteristic);

  @async
  void setNotify(String characteristic, bool enabled);

  void openBluetoothSettings();
}

@FlutterApi()
abstract class AppleGattFlutterApi {
  /// A notification from a characteristic that has notify on.
  void onValue(String characteristic, Uint8List value);

  /// The link dropped, such as when the iPhone went out of reach.
  void onDisconnected(String deviceId);
}
