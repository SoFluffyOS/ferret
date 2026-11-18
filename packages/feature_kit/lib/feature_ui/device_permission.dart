import 'package:flutter/widgets.dart';

/// Something one paired device may do on this one, as a switch on that
/// device's page, such as "Control this Mac without asking".
class DevicePermission {
  const DevicePermission({
    required this.label,
    required this.value,
    required this.onChanged,
    this.detail = '',
  });

  /// What the device may do, naming this device: "Show its screen here".
  final String label;

  /// One more line when the switch needs it, or empty.
  final String detail;

  final bool value;
  final ValueChanged<bool> onChanged;
}
