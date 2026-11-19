import 'dart:io';

import 'package:ferret_battery/src/battery_level.dart';
import 'package:ferret_battery/src/channel_battery_source.dart';
import 'package:ferret_battery/src/desktop_battery_readers.dart';
import 'package:ferret_battery/src/polling_battery_source.dart';

/// This device's battery: phones tell when it changes, computers are read
/// every couple of minutes. Null where there is no battery.
abstract interface class BatterySource {
  factory BatterySource.current() {
    if (Platform.isAndroid || Platform.isIOS) {
      return ChannelBatterySource();
    }

    if (Platform.isMacOS) {
      return PollingBatterySource(DesktopBatteryReaders.mac);
    }

    if (Platform.isWindows) {
      return PollingBatterySource(DesktopBatteryReaders.windows);
    }

    if (Platform.isLinux) {
      return PollingBatterySource(DesktopBatteryReaders.linux);
    }

    return PollingBatterySource(() async => null);
  }

  Future<BatteryLevel?> read();

  /// The level each time it changes. Listening is what starts watching.
  Stream<BatteryLevel?> get changes;
}
