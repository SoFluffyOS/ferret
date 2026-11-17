import 'package:protocol/protocol.dart';

/// What this device tells others about itself.
class LocalDevice {
  const LocalDevice({
    required this.name,
    required this.platform,
    required this.formFactor,
    this.model = '',
    this.appVersion = '',
  });

  final String name;
  final Platform platform;
  final FormFactor formFactor;
  final String model;
  final String appVersion;

  DeviceInfo toInfo(String deviceId) => DeviceInfo(
    id: deviceId,
    name: name,
    platform: platform,
    formFactor: formFactor,
    model: model,
    appVersion: appVersion,
    protocolVersion: protocolVersion,
  );
}

/// The protocol version this build speaks.
const protocolVersion = 1;
