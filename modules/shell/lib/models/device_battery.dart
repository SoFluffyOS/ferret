import 'package:engine/engine.dart';

/// A connected device's battery, as it last reported it.
typedef DeviceBattery = ({int percent, bool charging});

extension DeviceStatusBattery on DeviceStatus {
  /// Null while it is offline, and for a device without a battery or an
  /// older Ferret that doesn't say.
  DeviceBattery? get battery {
    final presence = session?.remotePresence;
    if (presence == null) {
      return null;
    }

    final percent = presence.batteryPercent;
    if (percent < 0 || percent > 100) {
      return null;
    }

    return (percent: percent, charging: presence.charging);
  }
}
