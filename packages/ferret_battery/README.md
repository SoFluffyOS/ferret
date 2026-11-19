# ferret_battery

Reads this device's battery level and whether it charges. Part of [Ferret](../../README.md), usable on its own.

```dart
final battery = BatterySource.current();
print(await battery.read()); // BatteryLevel(62%, charging) or null on a desktop
battery.changes.listen(print);
```

| Platform | How |
|---|---|
| Android | `ACTION_BATTERY_CHANGED`, listened to only while someone listens |
| iOS | `UIDevice.batteryLevel` with battery monitoring on |
| macOS | `pmset -g batt`, every two minutes |
| Windows | `GetSystemPowerStatus`, every two minutes |
| Linux | `/sys/class/power_supply/BAT*`, every two minutes |

A computer without a battery reads `null`.
