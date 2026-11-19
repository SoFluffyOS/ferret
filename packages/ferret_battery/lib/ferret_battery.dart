/// Reads this device's battery level and whether it charges: the system's
/// battery broadcast on Android, `UIDevice` on iOS, and on laptops `pmset`,
/// `GetSystemPowerStatus` or `/sys/class/power_supply`.
library;

export 'package:ferret_battery/src/battery_level.dart';
export 'package:ferret_battery/src/battery_source.dart';
export 'package:ferret_battery/src/channel_battery_source.dart';
export 'package:ferret_battery/src/desktop_battery_readers.dart';
export 'package:ferret_battery/src/polling_battery_source.dart';
