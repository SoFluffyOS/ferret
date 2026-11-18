import 'package:protocol/protocol.dart';

/// A device that can receive drops: a connected paired device, or a
/// LocalSend device found on the network.
class DropTarget {
  const DropTarget({
    required this.deviceId,
    required this.name,
    required this.formFactor,
    required this.platform,
    this.isLocalSend = false,
    this.detail = '',
  });

  final String deviceId;
  final String name;
  final FormFactor formFactor;
  final Platform platform;

  /// A LocalSend device on the network, not a paired Ferret device.
  final bool isLocalSend;

  /// For LocalSend devices, the model they report, such as "iPhone".
  final String detail;
}
