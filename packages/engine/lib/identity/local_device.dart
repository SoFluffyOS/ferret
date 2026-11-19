import 'package:protocol/protocol.dart';

/// What this device tells others about itself.
class LocalDevice {
  const LocalDevice({
    required this.name,
    required this.platform,
    required this.formFactor,
    this.model = '',
    this.appVersion = '',
    this.newestProtocol = protocolVersion,
    this.oldestProtocol = oldestProtocolVersion,
  });

  final String name;
  final Platform platform;
  final FormFactor formFactor;
  final String model;
  final String appVersion;

  /// The protocol versions this build speaks, from [oldestProtocol] to
  /// [newestProtocol]. Only tests set them, to play an older or newer app.
  final int newestProtocol;
  final int oldestProtocol;

  DeviceInfo toInfo(String deviceId) => DeviceInfo(
    id: deviceId,
    name: name,
    platform: platform,
    formFactor: formFactor,
    model: model,
    appVersion: appVersion,
    protocolVersion: newestProtocol,
    oldestProtocolVersion: oldestProtocol,
  );

  /// The same device under another [name].
  LocalDevice renamed(String name) => LocalDevice(
    name: name,
    platform: platform,
    formFactor: formFactor,
    model: model,
    appVersion: appVersion,
    newestProtocol: newestProtocol,
    oldestProtocol: oldestProtocol,
  );
}

/// The protocol version this build speaks.
const protocolVersion = 1;

/// The oldest protocol version this build still speaks. Raising it means
/// devices still on an older Ferret must update before they connect again.
const oldestProtocolVersion = 1;
