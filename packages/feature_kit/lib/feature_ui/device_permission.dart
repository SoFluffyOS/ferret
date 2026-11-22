import 'package:flutter/widgets.dart';

/// Something one paired device may do on this one, as a switch on that
/// device's page, such as "Control this Mac without asking".
class DevicePermission {
  const DevicePermission({
    required this.label,
    required this.value,
    required this.onChanged,
    this.detail = '',
    bool? inUse,
  }) : inUse = inUse ?? value;

  /// What the device may do, naming this device: "Show its screen here".
  final String label;

  /// One more line when the switch needs it, or empty.
  final String detail;

  final bool value;

  /// Whether the switch is doing something right now: on, and the other
  /// side uses it. A switch that is on by default but has nothing to do
  /// yet (notifications the phone doesn't send) can fold away with the
  /// rest until Ferret has been used once.
  final bool inUse;
  final ValueChanged<bool> onChanged;
}
