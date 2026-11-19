import 'dart:ffi';
import 'dart:io';

import 'package:ferret_battery/src/battery_level.dart';
import 'package:ffi/ffi.dart';

/// Reads a laptop's battery without any native code of Ferret's own.
abstract final class DesktopBatteryReaders {
  /// `pmset -g batt`: "Now drawing from 'AC Power' … 62%; charging; …".
  static Future<BatteryLevel?> mac() async {
    final result = await Process.run('pmset', ['-g', 'batt']);
    if (result.exitCode != 0) {
      return null;
    }

    return parsePmset('${result.stdout}');
  }

  static BatteryLevel? parsePmset(String output) {
    final match = RegExp(r'(\d+)%;\s*([^;]+);').firstMatch(output);
    if (match == null) {
      return null;
    }

    final percent = int.parse(match.group(1) ?? '0');
    final state = (match.group(2) ?? '').trim();

    return BatteryLevel(
      percent.clamp(0, 100),
      charging: state != 'discharging',
    );
  }

  /// `GetSystemPowerStatus`: no battery when BatteryFlag has bit 128.
  static Future<BatteryLevel?> windows() async {
    final status = calloc<_SystemPowerStatus>();
    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final getStatus = kernel32
          .lookupFunction<
            Int32 Function(Pointer<_SystemPowerStatus>),
            int Function(Pointer<_SystemPowerStatus>)
          >('GetSystemPowerStatus');
      if (getStatus(status) == 0) {
        return null;
      }

      final power = status.ref;
      return windowsLevel(
        acLine: power.acLineStatus,
        flag: power.batteryFlag,
        percent: power.batteryLifePercent,
      );
    } on Object {
      return null;
    } finally {
      calloc.free(status);
    }
  }

  static BatteryLevel? windowsLevel({
    required int acLine,
    required int flag,
    required int percent,
  }) {
    const noBattery = 128;
    const unknown = 255;
    if (flag & noBattery != 0 || flag == unknown || percent > 100) {
      return null;
    }

    const chargingFlag = 8;
    return BatteryLevel(
      percent,
      charging: flag & chargingFlag != 0 || acLine == 1,
    );
  }

  /// The first `BAT*` under `/sys/class/power_supply`.
  static Future<BatteryLevel?> linux({
    String root = '/sys/class/power_supply',
  }) async {
    final folder = Directory(root);
    if (!folder.existsSync()) {
      return null;
    }

    final batteries =
        folder
            .listSync()
            .where(
              (entry) =>
                  entry.uri.pathSegments.any((part) => part.startsWith('BAT')),
            )
            .toList()
          ..sort((first, second) => first.path.compareTo(second.path));
    for (final battery in batteries) {
      final capacity = File('${battery.path}/capacity');
      final status = File('${battery.path}/status');
      if (!capacity.existsSync()) {
        continue;
      }

      final percent = int.tryParse(capacity.readAsStringSync().trim());
      if (percent == null) {
        continue;
      }

      final state = switch (status.existsSync()) {
        true => status.readAsStringSync().trim(),
        false => '',
      };
      return BatteryLevel(
        percent.clamp(0, 100),
        charging: state == 'Charging' || state == 'Full',
      );
    }

    return null;
  }
}

final class _SystemPowerStatus extends Struct {
  @Uint8()
  external int acLineStatus;

  @Uint8()
  external int batteryFlag;

  @Uint8()
  external int batteryLifePercent;

  @Uint8()
  external int systemStatusFlag;

  @Uint32()
  external int batteryLifeTime;

  @Uint32()
  external int batteryFullLifeTime;
}
