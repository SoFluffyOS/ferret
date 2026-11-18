import 'package:protocol/protocol.dart';

/// A connected device that can receive drops.
class DropTarget {
  const DropTarget({
    required this.deviceId,
    required this.name,
    required this.formFactor,
    required this.platform,
  });

  final String deviceId;
  final String name;
  final FormFactor formFactor;
  final Platform platform;
}
